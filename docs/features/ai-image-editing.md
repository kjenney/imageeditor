# AI Image Editing with Qwen-Image-Edit-2511

The Image Editor integrates Qwen-Image-Edit-2511, a powerful AI diffusion model for text-guided image editing.

## Overview

Qwen-Image-Edit-2511 enables natural language image editing without masks or manual selection. Simply describe what you want to change, and the AI handles the rest.

**Key Capabilities:**
- Object addition, removal, and replacement
- Background replacement and removal
- Style transfer (Ghibli, Pixar, anime, etc.)
- Text editing on images
- Clothing and accessory modifications
- Season and lighting changes
- Photo restoration and enhancement

## API Endpoints

When `enable_qwen_image_edit = true`, the following API endpoints are available:

### Health Check
```bash
GET /health
```
Returns server status and model loading state.

### Model Info
```bash
GET /info
```
Returns model variant, GPU info, and memory usage.

### Edit Image (Multipart Form)
```bash
POST /edit
Content-Type: multipart/form-data

Parameters:
- image: Image file (PNG, JPG)
- prompt: Edit instruction (required)
- negative_prompt: What to avoid (optional)
- num_inference_steps: Quality steps (default: 40)
- guidance_scale: Prompt adherence (default: 1.0)
- true_cfg_scale: Consistency control (default: 4.0)
- seed: For reproducibility (optional)
```

### Edit Image (Base64)
```bash
POST /edit/base64
Content-Type: application/json

{
  "image": "<base64-encoded-image>",
  "prompt": "your edit instruction",
  "negative_prompt": null,
  "num_inference_steps": 40,
  "guidance_scale": 1.0,
  "true_cfg_scale": 4.0,
  "seed": null
}
```

## Prompt Examples

### Object Removal
```
"remove the person on the right"
"remove the trash can from the scene"
"remove the watermark"
```

### Object Addition
```
"add a red umbrella in her hand"
"add a cat sitting on the couch"
"add sunglasses to the person"
```

### Background Changes
```
"replace background with studio white"
"change the background to a sunset beach"
"replace background with a futuristic cityscape at night"
```

### Style Transfer
```
"transform into Studio Ghibli anime style"
"convert to Pixar 3D animation style"
"make it look like a watercolor painting"
"transform into pixel art style"
```

### Clothing & Accessories
```
"change the t-shirt to a formal suit"
"add a cowboy hat"
"change the dress color to red"
```

### Lighting & Environment
```
"use soft light to relight the image"
"change from day to night"
"convert summer scene to winter with snow"
"add dramatic sunset lighting"
```

### Text Editing
```
"change the sign text to 'Welcome'"
"replace the billboard text with 'SALE 50% OFF'"
```

### Photo Enhancement
```
"enhance the image quality"
"remove blur and sharpen details"
"fix the lighting and color balance"
```

## Best Practices

### Writing Effective Prompts

1. **Be Direct**: Use action verbs like "replace," "add," "remove," "change"
   - Good: `"remove the person in the background"`
   - Bad: `"I would like the background person to not be there"`

2. **Be Specific**: Name objects and regions explicitly
   - Good: `"change the blue car to red"`
   - Bad: `"change the color"`

3. **Keep It Concise**: 50-200 characters works best
   - Good: `"replace background with a sunny beach, blue sky"`
   - Bad: `"I want you to take the current background and replace it with something that looks like a beautiful sunny beach with crystal clear water and a bright blue sky with some fluffy white clouds"`

4. **One Edit at a Time**: For complex changes, do multiple passes
   - First: `"remove the person on the left"`
   - Then: `"add a potted plant where the person was"`

### Parameter Tuning

| Parameter | Default | Description |
|-----------|---------|-------------|
| `num_inference_steps` | 40 | Higher = better quality, slower. Range: 20-50 |
| `true_cfg_scale` | 4.0 | Controls consistency. Keep at 4.0 for best results |
| `guidance_scale` | 1.0 | Prompt adherence. 1.0 works well for edits |
| `seed` | random | Set for reproducible results |

### Quality Tips

- **For subtle changes**: Use shorter, precise prompts
- **For creative restyling**: Allow broader descriptions
- **For text on images**: The model handles Chinese and English text well
- **For people**: Works best with clear, well-lit subjects

## Usage Examples

### cURL Examples

**Remove an object:**
```bash
curl -X POST "http://<ip>:8000/edit" \
  -F "image=@photo.jpg" \
  -F "prompt=remove the person in the background" \
  -o edited.png
```

**Style transfer:**
```bash
curl -X POST "http://<ip>:8000/edit" \
  -F "image=@photo.jpg" \
  -F "prompt=transform into Studio Ghibli anime style" \
  -F "num_inference_steps=50" \
  -o ghibli_style.png
```

**Background replacement:**
```bash
curl -X POST "http://<ip>:8000/edit" \
  -F "image=@portrait.jpg" \
  -F "prompt=replace background with a professional studio gradient" \
  -o professional_headshot.png
```

### JavaScript/Fetch Example

```javascript
async function editImage(imageFile, prompt) {
  const formData = new FormData();
  formData.append('image', imageFile);
  formData.append('prompt', prompt);
  formData.append('num_inference_steps', 40);

  const response = await fetch('http://<ip>:8000/edit', {
    method: 'POST',
    body: formData
  });

  if (response.ok) {
    const blob = await response.blob();
    return URL.createObjectURL(blob);
  }
  throw new Error('Edit failed');
}

// Usage
const editedImageUrl = await editImage(file, 'add sunglasses');
```

### Python Example

```python
import requests

def edit_image(image_path, prompt, output_path):
    with open(image_path, 'rb') as f:
        response = requests.post(
            'http://<ip>:8000/edit',
            files={'image': f},
            data={
                'prompt': prompt,
                'num_inference_steps': 40,
                'true_cfg_scale': 4.0
            }
        )

    if response.status_code == 200:
        with open(output_path, 'wb') as out:
            out.write(response.content)
        return output_path
    raise Exception(f"Error: {response.text}")

# Usage
edit_image('input.jpg', 'change to winter scene with snow', 'winter.png')
```

## Limitations

- **Facial expressions**: Modifying facial expressions may not work well
- **Fine details**: Very small text or intricate patterns may be challenging
- **Multiple edits**: Complex multi-step edits work better as separate calls
- **Processing time**: Expect 10-30 seconds per edit depending on image size

## Troubleshooting

### Model Not Loading
- Check GPU memory: `nvidia-smi`
- View logs: `journalctl -u diffusion-server -f`
- Verify CUDA: `curl http://localhost:8000/info`

### Poor Results
- Try more specific prompts
- Increase `num_inference_steps` to 50
- Use `seed` parameter for reproducible testing
- Check that `true_cfg_scale` is set to 4.0

### Timeout Errors
- First request after startup may take longer (model loading)
- Large images take more time to process
- Consider setting `model_preload = true` in Terraform config

## Resources

- [Qwen-Image-Edit-2511 on HuggingFace](https://huggingface.co/Qwen/Qwen-Image-Edit-2511)
- [Qwen-Image GitHub Repository](https://github.com/QwenLM/Qwen-Image)
- [Full Tutorial with 26 Demo Cases](https://huggingface.co/blog/MonsterMMORPG/qwen-image-edit-full-tutorial-26-different-demo)
- [Prompt Best Practices](https://imagebyqwen.com/prompt)
