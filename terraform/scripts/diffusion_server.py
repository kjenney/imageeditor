#!/usr/bin/env python3
"""
FastAPI server for Qwen-Image-Edit-2511 diffusion model.
Provides REST API for AI-powered image editing.
"""
import os
import io
import base64
import logging
from typing import Optional
from contextlib import asynccontextmanager

import torch
from PIL import Image
from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.responses import StreamingResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from huggingface_hub import hf_hub_download
from safetensors.torch import load_file as load_safetensors

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Global model storage
model_state = {
    "pipeline": None,
    "loaded": False,
    "model_id": None
}

# Environment configuration
MODEL_VARIANT = os.getenv("MODEL_VARIANT", "full")
MODEL_PRELOAD = os.getenv("MODEL_PRELOAD", "true").lower() == "true"
HF_TOKEN = os.getenv("HF_TOKEN", None) or None  # Convert empty string to None

# Model configuration
BASE_MODEL_ID = "Qwen/Qwen-Image-Edit-2511"
FP8_WEIGHTS_REPO = "1038lab/Qwen-Image-Edit-2511-FP8"
FP8_WEIGHTS_FILE = "Qwen-Image-Edit-2511-FP8_e4m3fn.safetensors"


def load_fp8_model():
    """Load the pipeline with FP8 transformer weights for reduced memory usage."""
    from diffusers import QwenImageEditPlusPipeline, QwenImageTransformer2DModel

    logger.info("Loading FP8 variant for memory efficiency")

    # Download FP8 weights
    logger.info(f"Downloading FP8 weights from: {FP8_WEIGHTS_REPO}/{FP8_WEIGHTS_FILE}")
    fp8_weights_path = hf_hub_download(
        repo_id=FP8_WEIGHTS_REPO,
        filename=FP8_WEIGHTS_FILE,
        token=HF_TOKEN,
    )

    # Load transformer directly from FP8 safetensors file
    logger.info("Loading transformer from FP8 weights...")
    transformer = QwenImageTransformer2DModel.from_single_file(
        fp8_weights_path,
        config=BASE_MODEL_ID,
        subfolder="transformer",
        torch_dtype=torch.bfloat16,
        token=HF_TOKEN,
    )
    logger.info("FP8 transformer loaded successfully")

    # Load the rest of the pipeline (VAE, text encoder, etc.)
    logger.info(f"Loading remaining pipeline components from: {BASE_MODEL_ID}")
    pipeline = QwenImageEditPlusPipeline.from_pretrained(
        BASE_MODEL_ID,
        transformer=transformer,
        torch_dtype=torch.bfloat16,
        low_cpu_mem_usage=True,
        token=HF_TOKEN,
    )

    return pipeline


def load_model():
    """Load the Qwen Image Edit pipeline."""
    from diffusers import QwenImageEditPlusPipeline

    logger.info(f"Loading model variant: {MODEL_VARIANT}")
    logger.info(f"CUDA available: {torch.cuda.is_available()}")

    if torch.cuda.is_available():
        logger.info(f"GPU: {torch.cuda.get_device_name(0)}")
        logger.info(f"GPU Memory: {torch.cuda.get_device_properties(0).total_memory / (1024**3):.1f} GB")

    if MODEL_VARIANT == "fp8":
        pipeline = load_fp8_model()
        model_id = f"{BASE_MODEL_ID} + FP8"
    else:
        # Full variant: Load complete model directly
        logger.info(f"Loading full model: {BASE_MODEL_ID}")
        pipeline = QwenImageEditPlusPipeline.from_pretrained(
            BASE_MODEL_ID,
            torch_dtype=torch.bfloat16,
            low_cpu_mem_usage=True,
            token=HF_TOKEN,
        )
        model_id = BASE_MODEL_ID

    # Enable memory optimizations - keeps components on CPU until needed
    pipeline.enable_model_cpu_offload()

    model_state["pipeline"] = pipeline
    model_state["loaded"] = True
    model_state["model_id"] = model_id

    logger.info(f"Model loaded successfully: {model_id}")
    return pipeline


def get_pipeline():
    """Get or load the pipeline."""
    if not model_state["loaded"]:
        load_model()
    return model_state["pipeline"]


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler."""
    if MODEL_PRELOAD:
        logger.info("Preloading model on startup...")
        try:
            load_model()
        except Exception as e:
            logger.error(f"Failed to preload model: {e}")
            # Continue anyway - model will load on first request
    yield
    # Cleanup
    if model_state["pipeline"]:
        del model_state["pipeline"]
        if torch.cuda.is_available():
            torch.cuda.empty_cache()


app = FastAPI(
    title="Qwen Image Edit API",
    description="AI-powered image editing using Qwen-Image-Edit-2511",
    version="1.0.0",
    lifespan=lifespan
)

# Enable CORS for frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class EditRequestBase64(BaseModel):
    """Request model for image editing via base64."""
    image: str  # Base64 encoded image
    prompt: str
    negative_prompt: Optional[str] = None
    num_inference_steps: int = 40
    guidance_scale: float = 1.0
    true_cfg_scale: float = 4.0
    seed: Optional[int] = None


class InfoResponse(BaseModel):
    """Model info response."""
    model_id: Optional[str]
    variant: str
    loaded: bool
    cuda_available: bool
    gpu_name: Optional[str]
    gpu_memory_gb: Optional[float]


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "model_loaded": model_state["loaded"],
        "cuda_available": torch.cuda.is_available()
    }


@app.get("/info", response_model=InfoResponse)
async def get_info():
    """Get model and system information."""
    gpu_name = None
    gpu_memory = None

    if torch.cuda.is_available():
        gpu_name = torch.cuda.get_device_name(0)
        gpu_memory = torch.cuda.get_device_properties(0).total_memory / (1024**3)

    return InfoResponse(
        model_id=model_state.get("model_id") or BASE_MODEL_ID,
        variant=MODEL_VARIANT,
        loaded=model_state["loaded"],
        cuda_available=torch.cuda.is_available(),
        gpu_name=gpu_name,
        gpu_memory_gb=gpu_memory
    )


@app.post("/edit")
async def edit_image(
    image: UploadFile = File(...),
    prompt: str = Form(...),
    negative_prompt: Optional[str] = Form(None),
    num_inference_steps: int = Form(40),
    guidance_scale: float = Form(1.0),
    true_cfg_scale: float = Form(4.0),
    seed: Optional[int] = Form(None),
):
    """
    Edit an image using AI.

    - **image**: Image file to edit (PNG, JPG, etc.)
    - **prompt**: Text description of desired edit
    - **negative_prompt**: What to avoid in the edit (optional)
    - **num_inference_steps**: Number of denoising steps (default: 40)
    - **guidance_scale**: How closely to follow the prompt (default: 1.0)
    - **true_cfg_scale**: True CFG scale for consistency (default: 4.0)
    - **seed**: Random seed for reproducibility (optional)
    """
    try:
        # Load image
        image_data = await image.read()
        input_image = Image.open(io.BytesIO(image_data)).convert("RGB")
        logger.info(f"Received image: {input_image.size}, prompt: {prompt[:50]}...")

        # Get pipeline
        pipeline = get_pipeline()

        # Set seed if provided
        generator = None
        if seed is not None:
            generator = torch.Generator(device="cuda").manual_seed(seed)

        # Run inference
        with torch.inference_mode():
            result = pipeline(
                prompt=prompt,
                image=[input_image],
                negative_prompt=negative_prompt or " ",
                num_inference_steps=num_inference_steps,
                guidance_scale=guidance_scale,
                true_cfg_scale=true_cfg_scale,
                generator=generator,
                num_images_per_prompt=1,
            ).images[0]

        # Convert to bytes
        output_buffer = io.BytesIO()
        result.save(output_buffer, format="PNG")
        output_buffer.seek(0)

        logger.info("Image edit completed successfully")
        return StreamingResponse(
            output_buffer,
            media_type="image/png",
            headers={"Content-Disposition": "attachment; filename=edited_image.png"}
        )

    except Exception as e:
        logger.error(f"Error processing image: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/edit/base64")
async def edit_image_base64(request: EditRequestBase64):
    """
    Edit an image using base64 encoding.
    Returns base64 encoded result.
    """
    try:
        # Decode base64 image
        image_data = base64.b64decode(request.image)
        input_image = Image.open(io.BytesIO(image_data)).convert("RGB")
        logger.info(f"Received base64 image: {input_image.size}, prompt: {request.prompt[:50]}...")

        # Get pipeline
        pipeline = get_pipeline()

        # Set seed if provided
        generator = None
        if request.seed is not None:
            generator = torch.Generator(device="cuda").manual_seed(request.seed)

        # Run inference
        with torch.inference_mode():
            result = pipeline(
                prompt=request.prompt,
                image=[input_image],
                negative_prompt=request.negative_prompt or " ",
                num_inference_steps=request.num_inference_steps,
                guidance_scale=request.guidance_scale,
                true_cfg_scale=request.true_cfg_scale,
                generator=generator,
                num_images_per_prompt=1,
            ).images[0]

        # Convert to base64
        output_buffer = io.BytesIO()
        result.save(output_buffer, format="PNG")
        output_buffer.seek(0)
        result_base64 = base64.b64encode(output_buffer.getvalue()).decode()

        logger.info("Base64 image edit completed successfully")
        return JSONResponse({
            "image": result_base64,
            "format": "png"
        })

    except Exception as e:
        logger.error(f"Error processing image: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    logger.info(f"Starting server on port {port}")
    uvicorn.run(app, host="0.0.0.0", port=port)
