import { useState, useCallback } from 'react';

interface AIEditPanelProps {
  onEdit: (prompt: string, options: AIEditOptions) => Promise<void>;
  isProcessing: boolean;
  isAvailable: boolean;
  error: string | null;
}

export interface AIEditOptions {
  negativePrompt?: string;
  numInferenceSteps: number;
  seed?: number;
}

const PROMPT_SUGGESTIONS = [
  'Remove the background',
  'Add a sunset sky background',
  'Transform into Studio Ghibli style',
  'Make it look like a watercolor painting',
  'Add soft lighting',
  'Convert to black and white',
  'Add a vintage film effect',
  'Remove text from the image',
];

export function AIEditPanel({ onEdit, isProcessing, isAvailable, error }: AIEditPanelProps) {
  const [prompt, setPrompt] = useState('');
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [negativePrompt, setNegativePrompt] = useState('');
  const [numInferenceSteps, setNumInferenceSteps] = useState(40);
  const [seed, setSeed] = useState<string>('');

  const handleSubmit = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault();
      if (!prompt.trim() || isProcessing) return;

      await onEdit(prompt.trim(), {
        negativePrompt: negativePrompt.trim() || undefined,
        numInferenceSteps,
        seed: seed ? parseInt(seed, 10) : undefined,
      });
    },
    [prompt, negativePrompt, numInferenceSteps, seed, isProcessing, onEdit]
  );

  const handleSuggestionClick = useCallback((suggestion: string) => {
    setPrompt(suggestion);
  }, []);

  const handleRandomSeed = useCallback(() => {
    setSeed(Math.floor(Math.random() * 1000000).toString());
  }, []);

  if (!isAvailable) {
    return (
      <div className="ai-edit-panel">
        <div className="ai-panel-header">
          <h3 className="toolbar-title">AI Edit</h3>
        </div>
        <div className="ai-unavailable">
          <p>AI editing is not available.</p>
          <p className="ai-hint">
            Enable <code>enable_qwen_image_edit</code> in Terraform and deploy a GPU instance.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="ai-edit-panel">
      <div className="ai-panel-header">
        <h3 className="toolbar-title">AI Edit</h3>
        <span className="ai-status available">Ready</span>
      </div>

      <form onSubmit={handleSubmit} className="ai-form">
        <div className="ai-prompt-container">
          <textarea
            className="ai-prompt-input"
            placeholder="Describe what you want to change..."
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            disabled={isProcessing}
            rows={3}
          />
        </div>

        <div className="ai-suggestions">
          <span className="ai-suggestions-label">Try:</span>
          <div className="ai-suggestion-chips">
            {PROMPT_SUGGESTIONS.slice(0, 4).map((suggestion) => (
              <button
                key={suggestion}
                type="button"
                className="ai-suggestion-chip"
                onClick={() => handleSuggestionClick(suggestion)}
                disabled={isProcessing}
              >
                {suggestion}
              </button>
            ))}
          </div>
        </div>

        <button
          type="button"
          className="ai-advanced-toggle"
          onClick={() => setShowAdvanced(!showAdvanced)}
        >
          {showAdvanced ? '▼ Hide' : '▶ Advanced'} Options
        </button>

        {showAdvanced && (
          <div className="ai-advanced-options">
            <label className="setting-label">
              Negative prompt (what to avoid):
              <textarea
                className="ai-negative-prompt"
                placeholder="low quality, blurry, distorted..."
                value={negativePrompt}
                onChange={(e) => setNegativePrompt(e.target.value)}
                disabled={isProcessing}
                rows={2}
              />
            </label>

            <label className="setting-label">
              Quality steps: {numInferenceSteps}
              <input
                type="range"
                min="20"
                max="50"
                value={numInferenceSteps}
                onChange={(e) => setNumInferenceSteps(Number(e.target.value))}
                className="brush-size-slider"
                disabled={isProcessing}
              />
              <span className="ai-hint">Higher = better quality, slower</span>
            </label>

            <label className="setting-label">
              Seed (for reproducibility):
              <div className="ai-seed-input">
                <input
                  type="number"
                  placeholder="Random"
                  value={seed}
                  onChange={(e) => setSeed(e.target.value)}
                  className="ai-seed-field"
                  disabled={isProcessing}
                />
                <button
                  type="button"
                  className="ai-seed-random"
                  onClick={handleRandomSeed}
                  disabled={isProcessing}
                  title="Generate random seed"
                >
                  🎲
                </button>
              </div>
            </label>
          </div>
        )}

        {error && <div className="ai-error">{error}</div>}

        <button
          type="submit"
          className="ai-submit-button"
          disabled={!prompt.trim() || isProcessing}
        >
          {isProcessing ? (
            <>
              <span className="ai-spinner"></span>
              Processing...
            </>
          ) : (
            'Apply AI Edit'
          )}
        </button>

        {isProcessing && (
          <p className="ai-processing-hint">This may take 10-30 seconds depending on the edit...</p>
        )}
      </form>
    </div>
  );
}

export default AIEditPanel;
