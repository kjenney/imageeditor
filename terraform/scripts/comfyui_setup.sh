#!/bin/bash
# ComfyUI + comfyui-api setup script for Qwen-Image-Edit-2511-Lightning
# This provides a REST API for AI image editing using the Lightning variant (4 steps)

set -e

COMFYUI_DIR="/opt/comfyui"
API_PORT="${DIFFUSION_PORT:-8000}"
COMFYUI_PORT="8188"
HF_TOKEN="${HF_TOKEN:-}"

echo "=== Setting up ComfyUI with Qwen-Image-Edit-2511-Lightning ==="

# Install system dependencies
echo "Installing system dependencies..."
dnf install -y git python3.11 python3.11-pip python3.11-devel

# Verify NVIDIA drivers
echo "Verifying NVIDIA drivers..."
if ! nvidia-smi; then
    echo "ERROR: NVIDIA drivers not found."
    exit 1
fi

# Create ComfyUI directory
mkdir -p $COMFYUI_DIR
cd $COMFYUI_DIR

# Clone ComfyUI
echo "Cloning ComfyUI..."
git clone https://github.com/comfyanonymous/ComfyUI.git .

# Create virtual environment with Python 3.11
echo "Creating Python 3.11 virtual environment..."
python3.11 -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install PyTorch with CUDA support
echo "Installing PyTorch with CUDA support..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install ComfyUI requirements
echo "Installing ComfyUI requirements..."
pip install -r requirements.txt

# Install additional dependencies for Qwen
pip install "transformers>=4.49.0" accelerate safetensors huggingface_hub qwen-vl-utils

# Install custom nodes
echo "Installing custom nodes..."
cd custom_nodes

# Install ComfyUI-GGUF for efficient GGUF model loading
echo "Installing ComfyUI-GGUF..."
git clone https://github.com/city96/ComfyUI-GGUF.git
cd ComfyUI-GGUF && pip install -r requirements.txt || true && cd ..

# Install QwenEditUtils for Qwen model support
echo "Installing QwenEditUtils..."
git clone https://github.com/lrzjason/Comfyui-QwenEditUtils.git
cd Comfyui-QwenEditUtils && pip install -r requirements.txt || true && cd ..

cd $COMFYUI_DIR

# Create model directories
echo "Creating model directories..."
mkdir -p models/diffusion_models
mkdir -p models/vae
mkdir -p models/loras
mkdir -p models/clip
mkdir -p input
mkdir -p output

# Download Lightning LoRA only (base model loads from HuggingFace at runtime)
echo "Downloading Lightning LoRA..."

python3.11 << 'DOWNLOAD_EOF'
import os
from huggingface_hub import hf_hub_download

HF_TOKEN = os.environ.get('HF_TOKEN')

# Download Lightning LoRA for 4-step inference
print("Downloading Lightning LoRA for fast inference...")
hf_hub_download(
    repo_id="lightx2v/Qwen-Image-Edit-2511-Lightning",
    filename="Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors",
    local_dir="models/loras",
    token=HF_TOKEN
)

print("Lightning LoRA downloaded!")
print("Note: Base model will be downloaded from HuggingFace on first API request")
DOWNLOAD_EOF

# Create systemd service for ComfyUI
echo "Creating ComfyUI systemd service..."
cat > /etc/systemd/system/comfyui.service << EOF
[Unit]
Description=ComfyUI Server
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$COMFYUI_DIR
Environment="HF_TOKEN=$HF_TOKEN"
Environment="PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512"
ExecStart=$COMFYUI_DIR/venv/bin/python main.py --listen 0.0.0.0 --port $COMFYUI_PORT --enable-cors-header
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create a FastAPI server that uses diffusers directly with Lightning LoRA
echo "Creating FastAPI server with diffusers + Lightning..."
cat > $COMFYUI_DIR/api_wrapper.py << 'API_WRAPPER_EOF'
#!/usr/bin/env python3
"""
FastAPI server for Qwen-Image-Edit-2511 with Lightning LoRA.
Uses diffusers directly for reliable inference.
"""
import os
import io
import base64
import time
import logging
from typing import Optional
from contextlib import asynccontextmanager

import torch
from PIL import Image
from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.responses import StreamingResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Configuration
COMFYUI_DIR = os.getenv("COMFYUI_DIR", "/opt/comfyui")
MODEL_DIR = os.path.join(COMFYUI_DIR, "models", "Qwen-Image-Edit-2511")
LORA_PATH = os.path.join(COMFYUI_DIR, "models", "loras", "Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors")
HF_TOKEN = os.getenv("HF_TOKEN")

# Global model state
model_state = {
    "pipeline": None,
    "loaded": False
}


def load_model():
    """Load the Qwen Image Edit pipeline with Lightning LoRA."""
    from diffusers import QwenImageEditPlusPipeline

    logger.info("Loading Qwen-Image-Edit-2511 pipeline...")
    logger.info(f"LoRA path: {LORA_PATH}")
    logger.info(f"CUDA available: {torch.cuda.is_available()}")

    if torch.cuda.is_available():
        logger.info(f"GPU: {torch.cuda.get_device_name(0)}")
        logger.info(f"VRAM: {torch.cuda.get_device_properties(0).total_memory / (1024**3):.1f} GB")

    # Always load from HuggingFace to ensure proper tokenizer loading
    logger.info("Loading from HuggingFace: Qwen/Qwen-Image-Edit-2511")
    pipeline = QwenImageEditPlusPipeline.from_pretrained(
        "Qwen/Qwen-Image-Edit-2511",
        torch_dtype=torch.bfloat16,
        low_cpu_mem_usage=True,
        token=HF_TOKEN,
    )

    # Move to GPU
    pipeline.to("cuda")

    # Load Lightning LoRA for fast 4-step inference
    if os.path.exists(LORA_PATH):
        logger.info(f"Loading Lightning LoRA: {LORA_PATH}")
        pipeline.load_lora_weights(LORA_PATH)
        logger.info("Lightning LoRA loaded - using 4-step inference")
    else:
        logger.warning(f"Lightning LoRA not found at {LORA_PATH}, using default steps")

    # Enable memory optimizations
    try:
        pipeline.enable_xformers_memory_efficient_attention()
        logger.info("Enabled xformers memory-efficient attention")
    except Exception as e:
        logger.info(f"xformers not available: {e}")

    model_state["pipeline"] = pipeline
    model_state["loaded"] = True
    logger.info("Model loaded successfully!")
    return pipeline


def get_pipeline():
    """Get or load the pipeline."""
    if not model_state["loaded"]:
        load_model()
    return model_state["pipeline"]


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler."""
    logger.info("Starting up - loading model...")
    try:
        load_model()
    except Exception as e:
        logger.error(f"Failed to load model: {e}")
    yield
    # Cleanup
    if model_state["pipeline"]:
        del model_state["pipeline"]
        if torch.cuda.is_available():
            torch.cuda.empty_cache()


app = FastAPI(
    title="Qwen Image Edit API",
    description="AI-powered image editing using Qwen-Image-Edit-2511 with Lightning LoRA",
    version="2.0.0",
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
    image: str
    prompt: str
    negative_prompt: Optional[str] = None
    num_inference_steps: int = 4
    guidance_scale: float = 1.0
    true_cfg_scale: float = 4.0
    seed: Optional[int] = None


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy" if model_state["loaded"] else "loading",
        "model_loaded": model_state["loaded"],
        "cuda_available": torch.cuda.is_available(),
        "backend": "diffusers-lightning"
    }


@app.get("/info")
async def get_info():
    """Get model and system information."""
    gpu_name = None
    gpu_memory = None
    if torch.cuda.is_available():
        gpu_name = torch.cuda.get_device_name(0)
        gpu_memory = torch.cuda.get_device_properties(0).total_memory / (1024**3)

    return {
        "model_id": "Qwen/Qwen-Image-Edit-2511",
        "variant": "lightning",
        "loaded": model_state["loaded"],
        "cuda_available": torch.cuda.is_available(),
        "gpu_name": gpu_name,
        "gpu_memory_gb": gpu_memory,
        "backend": "diffusers-lightning",
        "inference_steps": 4
    }


@app.post("/edit")
async def edit_image(
    image: UploadFile = File(...),
    prompt: str = Form(...),
    negative_prompt: Optional[str] = Form(None),
    num_inference_steps: int = Form(4),
    guidance_scale: float = Form(1.0),
    true_cfg_scale: float = Form(4.0),
    seed: Optional[int] = Form(None),
):
    """Edit an image using AI."""
    try:
        # Load image
        image_data = await image.read()
        input_image = Image.open(io.BytesIO(image_data)).convert("RGB")
        logger.info(f"Processing image: {input_image.size}, prompt: {prompt[:50]}...")

        # Get pipeline
        pipeline = get_pipeline()

        # Set seed
        generator = None
        if seed is not None:
            generator = torch.Generator(device="cuda").manual_seed(seed)

        # Run inference
        start_time = time.time()
        with torch.inference_mode():
            result = pipeline(
                prompt=prompt,
                image=[input_image],
                negative_prompt=negative_prompt or "",
                num_inference_steps=num_inference_steps,
                guidance_scale=guidance_scale,
                true_cfg_scale=true_cfg_scale,
                generator=generator,
            ).images[0]

        elapsed = time.time() - start_time
        logger.info(f"Inference completed in {elapsed:.1f}s")

        # Convert to bytes
        output_buffer = io.BytesIO()
        result.save(output_buffer, format="PNG")
        output_buffer.seek(0)

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
    """Edit an image using base64 encoding."""
    try:
        # Decode image
        image_data = base64.b64decode(request.image)
        input_image = Image.open(io.BytesIO(image_data)).convert("RGB")
        logger.info(f"Processing base64 image: {input_image.size}, prompt: {request.prompt[:50]}...")

        # Get pipeline
        pipeline = get_pipeline()

        # Set seed
        generator = None
        if request.seed is not None:
            generator = torch.Generator(device="cuda").manual_seed(request.seed)

        # Run inference
        start_time = time.time()
        with torch.inference_mode():
            result = pipeline(
                prompt=request.prompt,
                image=[input_image],
                negative_prompt=request.negative_prompt or "",
                num_inference_steps=request.num_inference_steps,
                guidance_scale=request.guidance_scale,
                true_cfg_scale=request.true_cfg_scale,
                generator=generator,
            ).images[0]

        elapsed = time.time() - start_time
        logger.info(f"Base64 inference completed in {elapsed:.1f}s")

        # Convert to base64
        output_buffer = io.BytesIO()
        result.save(output_buffer, format="PNG")
        output_buffer.seek(0)
        result_base64 = base64.b64encode(output_buffer.getvalue()).decode()

        return JSONResponse({
            "image": result_base64,
            "format": "png"
        })

    except Exception as e:
        logger.error(f"Error processing base64 image: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    logger.info(f"Starting server on port {port}")
    uvicorn.run(app, host="0.0.0.0", port=port)
API_WRAPPER_EOF

# Create systemd service for API (diffusers-based, no ComfyUI dependency)
echo "Creating diffusion API systemd service..."
cat > /etc/systemd/system/diffusion-api.service << EOF
[Unit]
Description=Qwen Image Edit API (diffusers + Lightning)
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$COMFYUI_DIR
Environment="COMFYUI_DIR=$COMFYUI_DIR"
Environment="HF_TOKEN=$HF_TOKEN"
Environment="PORT=$API_PORT"
Environment="PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512"
ExecStart=$COMFYUI_DIR/venv/bin/python api_wrapper.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Install dependencies for the API
echo "Installing API dependencies..."
$COMFYUI_DIR/venv/bin/pip install fastapi uvicorn[standard] python-multipart Pillow pydantic
$COMFYUI_DIR/venv/bin/pip install "diffusers>=0.36.0"
$COMFYUI_DIR/venv/bin/pip install git+https://github.com/huggingface/transformers.git

# Reload systemd
systemctl daemon-reload

# Enable and start API service (ComfyUI not needed for diffusers approach)
systemctl enable diffusion-api

echo "Starting diffusion API..."
systemctl start diffusion-api

# Health check (model loading takes time)
echo "Waiting for model to load (this may take several minutes)..."
for i in {1..60}; do
    if curl -s "http://localhost:$API_PORT/health" | grep -q "healthy"; then
        echo "API is healthy!"
        break
    fi
    echo "Waiting for API to be ready... ($i/60)"
    sleep 10
done

echo "=== Diffusion API Setup Complete ==="
echo "API running on port: $API_PORT"
echo "Backend: diffusers + Lightning LoRA"
echo "Models location: $COMFYUI_DIR/models/"
