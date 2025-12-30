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

# Download models from Hugging Face
echo "Downloading Qwen-Image-Edit-2511-Lightning models..."

# Download the full model files needed for QwenEditUtils
python3.11 << 'DOWNLOAD_EOF'
import os
from huggingface_hub import hf_hub_download, snapshot_download

HF_TOKEN = os.environ.get('HF_TOKEN')

# Download the base Qwen model files
print("Downloading Qwen-Image-Edit-2511 model files...")
snapshot_download(
    repo_id="Qwen/Qwen-Image-Edit-2511",
    local_dir="models/Qwen-Image-Edit-2511",
    token=HF_TOKEN,
    ignore_patterns=["*.md", "*.txt"]
)

# Download Lightning LoRA for 4-step inference
print("Downloading Lightning LoRA...")
hf_hub_download(
    repo_id="lightx2v/Qwen-Image-Edit-2511-Lightning",
    filename="Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors",
    local_dir="models/loras",
    token=HF_TOKEN
)

print("All models downloaded successfully!")
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

# Create a simple FastAPI wrapper that's compatible with the existing frontend
echo "Creating FastAPI wrapper for ComfyUI..."
cat > $COMFYUI_DIR/api_wrapper.py << 'API_WRAPPER_EOF'
#!/usr/bin/env python3
"""
FastAPI wrapper for ComfyUI with Qwen-Image-Edit-2511-Lightning.
Provides REST API compatible with the imageeditor frontend.
"""
import os
import io
import base64
import json
import time
import uuid
import logging
import asyncio
from typing import Optional
from pathlib import Path

import httpx
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
COMFYUI_URL = os.getenv("COMFYUI_URL", "http://127.0.0.1:8188")
COMFYUI_DIR = os.getenv("COMFYUI_DIR", "/opt/comfyui")
INPUT_DIR = Path(COMFYUI_DIR) / "input"
OUTPUT_DIR = Path(COMFYUI_DIR) / "output"

# Ensure directories exist
INPUT_DIR.mkdir(exist_ok=True)
OUTPUT_DIR.mkdir(exist_ok=True)

app = FastAPI(
    title="Qwen Image Edit API",
    description="AI-powered image editing using Qwen-Image-Edit-2511-Lightning via ComfyUI",
    version="2.0.0"
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
    num_inference_steps: int = 4  # Lightning uses 4 steps
    guidance_scale: float = 1.0
    seed: Optional[int] = None


def create_workflow(image_filename: str, prompt: str, negative_prompt: str = "",
                    steps: int = 4, seed: int = 0) -> dict:
    """Create ComfyUI workflow for Qwen image editing with Lightning LoRA."""
    return {
        "1": {
            "class_type": "QwenEditLoader",
            "inputs": {
                "model_path": "Qwen-Image-Edit-2511",
                "precision": "bf16"
            }
        },
        "2": {
            "class_type": "LoadImage",
            "inputs": {
                "image": image_filename
            }
        },
        "3": {
            "class_type": "QwenEditImageEncode",
            "inputs": {
                "model": ["1", 0],
                "image": ["2", 0]
            }
        },
        "4": {
            "class_type": "QwenEditEncode",
            "inputs": {
                "model": ["1", 0],
                "prompt": prompt
            }
        },
        "5": {
            "class_type": "LoraLoaderModelOnly",
            "inputs": {
                "lora_name": "Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors",
                "strength_model": 1.0,
                "model": ["1", 1]
            }
        },
        "6": {
            "class_type": "QwenEditSampler",
            "inputs": {
                "model": ["5", 0],
                "positive": ["4", 0],
                "negative": negative_prompt if negative_prompt else "",
                "image_embeds": ["3", 0],
                "latent": ["3", 1],
                "steps": steps,
                "cfg": 1.0,
                "seed": seed,
                "sampler": "euler",
                "scheduler": "simple"
            }
        },
        "7": {
            "class_type": "QwenEditDecode",
            "inputs": {
                "model": ["1", 0],
                "samples": ["6", 0]
            }
        },
        "8": {
            "class_type": "SaveImage",
            "inputs": {
                "filename_prefix": "qwen_edit",
                "images": ["7", 0]
            }
        }
    }


async def wait_for_comfyui():
    """Wait for ComfyUI to be ready."""
    async with httpx.AsyncClient() as client:
        for _ in range(60):
            try:
                response = await client.get(f"{COMFYUI_URL}/system_stats")
                if response.status_code == 200:
                    return True
            except Exception:
                pass
            await asyncio.sleep(5)
    return False


async def queue_prompt(workflow: dict) -> str:
    """Queue a prompt in ComfyUI and return the prompt ID."""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{COMFYUI_URL}/prompt",
            json={"prompt": workflow}
        )
        if response.status_code != 200:
            raise HTTPException(status_code=500, detail=f"Failed to queue prompt: {response.text}")
        return response.json()["prompt_id"]


async def wait_for_result(prompt_id: str, timeout: int = 600) -> str:
    """Wait for ComfyUI to complete processing and return output filename."""
    start_time = time.time()
    async with httpx.AsyncClient() as client:
        while time.time() - start_time < timeout:
            response = await client.get(f"{COMFYUI_URL}/history/{prompt_id}")
            if response.status_code == 200:
                history = response.json()
                if prompt_id in history:
                    outputs = history[prompt_id].get("outputs", {})
                    for node_id, node_output in outputs.items():
                        if "images" in node_output:
                            return node_output["images"][0]["filename"]
            await asyncio.sleep(1)
    raise HTTPException(status_code=504, detail="Timeout waiting for result")


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{COMFYUI_URL}/system_stats", timeout=5)
            comfyui_ready = response.status_code == 200
    except Exception:
        comfyui_ready = False

    return {
        "status": "healthy" if comfyui_ready else "degraded",
        "model_loaded": comfyui_ready,
        "cuda_available": True,
        "backend": "comfyui"
    }


@app.get("/info")
async def get_info():
    """Get model and system information."""
    return {
        "model_id": "Qwen/Qwen-Image-Edit-2511",
        "variant": "lightning",
        "loaded": True,
        "cuda_available": True,
        "gpu_name": "NVIDIA GPU",
        "gpu_memory_gb": None,
        "backend": "comfyui",
        "inference_steps": 4
    }


@app.post("/edit")
async def edit_image(
    image: UploadFile = File(...),
    prompt: str = Form(...),
    negative_prompt: Optional[str] = Form(None),
    num_inference_steps: int = Form(4),
    guidance_scale: float = Form(1.0),
    seed: Optional[int] = Form(None),
):
    """Edit an image using AI via ComfyUI."""
    try:
        # Save input image
        image_id = str(uuid.uuid4())
        image_filename = f"{image_id}.png"
        image_path = INPUT_DIR / image_filename

        image_data = await image.read()
        input_image = Image.open(io.BytesIO(image_data)).convert("RGB")
        input_image.save(image_path, format="PNG")
        logger.info(f"Saved input image: {image_path}")

        # Create and queue workflow
        actual_seed = seed if seed is not None else int(time.time() * 1000) % 2**32
        workflow = create_workflow(
            image_filename=image_filename,
            prompt=prompt,
            negative_prompt=negative_prompt or "",
            steps=num_inference_steps,
            seed=actual_seed
        )

        prompt_id = await queue_prompt(workflow)
        logger.info(f"Queued prompt: {prompt_id}")

        # Wait for result
        output_filename = await wait_for_result(prompt_id)
        output_path = OUTPUT_DIR / output_filename
        logger.info(f"Got result: {output_path}")

        # Read and return result
        with open(output_path, "rb") as f:
            result_data = f.read()

        # Cleanup input file
        try:
            image_path.unlink()
        except Exception:
            pass

        return StreamingResponse(
            io.BytesIO(result_data),
            media_type="image/png",
            headers={"Content-Disposition": "attachment; filename=edited_image.png"}
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing image: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/edit/base64")
async def edit_image_base64(request: EditRequestBase64):
    """Edit an image using base64 encoding."""
    try:
        # Decode and save input image
        image_data = base64.b64decode(request.image)
        image_id = str(uuid.uuid4())
        image_filename = f"{image_id}.png"
        image_path = INPUT_DIR / image_filename

        input_image = Image.open(io.BytesIO(image_data)).convert("RGB")
        input_image.save(image_path, format="PNG")
        logger.info(f"Saved base64 input image: {image_path}")

        # Create and queue workflow
        actual_seed = request.seed if request.seed is not None else int(time.time() * 1000) % 2**32
        workflow = create_workflow(
            image_filename=image_filename,
            prompt=request.prompt,
            negative_prompt=request.negative_prompt or "",
            steps=request.num_inference_steps,
            seed=actual_seed
        )

        prompt_id = await queue_prompt(workflow)
        logger.info(f"Queued base64 prompt: {prompt_id}")

        # Wait for result
        output_filename = await wait_for_result(prompt_id)
        output_path = OUTPUT_DIR / output_filename
        logger.info(f"Got base64 result: {output_path}")

        # Read and encode result
        with open(output_path, "rb") as f:
            result_data = f.read()
        result_base64 = base64.b64encode(result_data).decode()

        # Cleanup input file
        try:
            image_path.unlink()
        except Exception:
            pass

        return JSONResponse({
            "image": result_base64,
            "format": "png"
        })

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing base64 image: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))

    # Wait for ComfyUI to be ready
    import asyncio
    logger.info("Waiting for ComfyUI to be ready...")
    if not asyncio.run(wait_for_comfyui()):
        logger.error("ComfyUI not ready after 5 minutes")
    else:
        logger.info("ComfyUI is ready!")

    logger.info(f"Starting API wrapper on port {port}")
    uvicorn.run(app, host="0.0.0.0", port=port)
API_WRAPPER_EOF

# Create systemd service for API wrapper
echo "Creating API wrapper systemd service..."
cat > /etc/systemd/system/diffusion-api.service << EOF
[Unit]
Description=Qwen Image Edit API (ComfyUI wrapper)
After=comfyui.service
Requires=comfyui.service

[Service]
Type=simple
User=root
WorkingDirectory=$COMFYUI_DIR
Environment="COMFYUI_URL=http://127.0.0.1:$COMFYUI_PORT"
Environment="COMFYUI_DIR=$COMFYUI_DIR"
Environment="PORT=$API_PORT"
ExecStartPre=/bin/sleep 30
ExecStart=$COMFYUI_DIR/venv/bin/python api_wrapper.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Install httpx for the API wrapper
$COMFYUI_DIR/venv/bin/pip install httpx

# Reload systemd
systemctl daemon-reload

# Enable services
systemctl enable comfyui
systemctl enable diffusion-api

# Start services
echo "Starting ComfyUI..."
systemctl start comfyui

echo "Waiting for ComfyUI to initialize (60 seconds)..."
sleep 60

echo "Starting API wrapper..."
systemctl start diffusion-api

# Health check
echo "Checking service status..."
for i in {1..30}; do
    if curl -s "http://localhost:$API_PORT/health" | grep -q "healthy"; then
        echo "API is healthy!"
        break
    fi
    echo "Waiting for API to be ready... ($i/30)"
    sleep 10
done

echo "=== ComfyUI Setup Complete ==="
echo "ComfyUI running on port: $COMFYUI_PORT"
echo "API running on port: $API_PORT"
echo "Models location: $COMFYUI_DIR/models/"
