/**
 * Diffusion API Service
 * Handles communication with the Qwen-Image-Edit-2511 FastAPI backend
 */

export interface DiffusionApiConfig {
  baseUrl: string;
}

export interface EditParams {
  prompt: string;
  negativePrompt?: string;
  numInferenceSteps?: number;
  guidanceScale?: number;
  trueCfgScale?: number;
  seed?: number;
}

export interface HealthResponse {
  status: string;
  model_loaded: boolean;
  cuda_available: boolean;
}

export interface InfoResponse {
  model_id: string | null;
  variant: string;
  loaded: boolean;
  cuda_available: boolean;
  gpu_name: string | null;
  gpu_memory_gb: number | null;
}

interface EditBase64Response {
  image: string;
  format: string;
}

// Default to same host, port 8000 (can be overridden)
const DEFAULT_BASE_URL =
  (import.meta.env.VITE_DIFFUSION_API_URL as string | undefined) ||
  `${window.location.protocol}//${window.location.hostname}:8000`;

class DiffusionApi {
  private baseUrl: string;

  constructor(config?: Partial<DiffusionApiConfig>) {
    this.baseUrl = config?.baseUrl || DEFAULT_BASE_URL;
  }

  /**
   * Set the API base URL
   */
  setBaseUrl(url: string): void {
    this.baseUrl = url;
  }

  /**
   * Get the current base URL
   */
  getBaseUrl(): string {
    return this.baseUrl;
  }

  /**
   * Check if the API is healthy
   */
  async health(): Promise<HealthResponse> {
    const response = await fetch(`${this.baseUrl}/health`);
    if (!response.ok) {
      throw new Error(`Health check failed: ${response.statusText}`);
    }
    return response.json() as Promise<HealthResponse>;
  }

  /**
   * Get model and system info
   */
  async info(): Promise<InfoResponse> {
    const response = await fetch(`${this.baseUrl}/info`);
    if (!response.ok) {
      throw new Error(`Info request failed: ${response.statusText}`);
    }
    return response.json() as Promise<InfoResponse>;
  }

  /**
   * Edit an image using a text prompt
   * @param imageBlob - The image to edit as a Blob
   * @param params - Edit parameters including prompt
   * @returns The edited image as a Blob
   */
  async editImage(imageBlob: Blob, params: EditParams): Promise<Blob> {
    const formData = new FormData();
    formData.append('image', imageBlob, 'image.png');
    formData.append('prompt', params.prompt);

    if (params.negativePrompt) {
      formData.append('negative_prompt', params.negativePrompt);
    }
    if (params.numInferenceSteps !== undefined) {
      formData.append('num_inference_steps', params.numInferenceSteps.toString());
    }
    if (params.guidanceScale !== undefined) {
      formData.append('guidance_scale', params.guidanceScale.toString());
    }
    if (params.trueCfgScale !== undefined) {
      formData.append('true_cfg_scale', params.trueCfgScale.toString());
    }
    if (params.seed !== undefined) {
      formData.append('seed', params.seed.toString());
    }

    const response = await fetch(`${this.baseUrl}/edit`, {
      method: 'POST',
      body: formData,
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Edit request failed: ${errorText}`);
    }

    return response.blob();
  }

  /**
   * Edit an image using base64 encoding
   * @param imageBase64 - The image as a base64 string (without data URL prefix)
   * @param params - Edit parameters including prompt
   * @returns The edited image as a base64 string
   */
  async editImageBase64(imageBase64: string, params: EditParams): Promise<string> {
    const response = await fetch(`${this.baseUrl}/edit/base64`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        image: imageBase64,
        prompt: params.prompt,
        negative_prompt: params.negativePrompt || null,
        num_inference_steps: params.numInferenceSteps || 40,
        guidance_scale: params.guidanceScale || 1.0,
        true_cfg_scale: params.trueCfgScale || 4.0,
        seed: params.seed || null,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Edit request failed: ${errorText}`);
    }

    const result = (await response.json()) as EditBase64Response;
    return result.image;
  }
}

// Export singleton instance
export const diffusionApi = new DiffusionApi();

// Export class for custom instances
export { DiffusionApi };
