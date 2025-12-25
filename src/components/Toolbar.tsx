import { EditorTool, ToolConfig } from '@/types';

interface ToolbarProps {
  currentTool: EditorTool;
  brushSize: number;
  brushColor: string;
  onToolChange: (tool: EditorTool) => void;
  onBrushSizeChange: (size: number) => void;
  onBrushColorChange: (color: string) => void;
  onLoadImage: () => void;
  onExport: () => void;
  onClear: () => void;
}

const tools: ToolConfig[] = [
  { id: 'select', name: 'Select', icon: '⊹', cursor: 'default' },
  { id: 'pen', name: 'Pen', icon: '✎', cursor: 'crosshair' },
  { id: 'brush', name: 'Brush', icon: '🖌', cursor: 'crosshair' },
  { id: 'eraser', name: 'Eraser', icon: '⌫', cursor: 'crosshair' },
  { id: 'rectangle', name: 'Rectangle', icon: '▢', cursor: 'crosshair' },
  { id: 'circle', name: 'Circle', icon: '○', cursor: 'crosshair' },
  { id: 'line', name: 'Line', icon: '╱', cursor: 'crosshair' },
  { id: 'text', name: 'Text', icon: 'T', cursor: 'text' },
];

export function Toolbar({
  currentTool,
  brushSize,
  brushColor,
  onToolChange,
  onBrushSizeChange,
  onBrushColorChange,
  onLoadImage,
  onExport,
  onClear,
}: ToolbarProps) {
  return (
    <div className="toolbar">
      <div className="toolbar-section">
        <h3 className="toolbar-title">Tools</h3>
        <div className="tool-buttons">
          {tools.map((tool) => (
            <button
              key={tool.id}
              className={`tool-button ${currentTool === tool.id ? 'active' : ''}`}
              onClick={() => onToolChange(tool.id)}
              title={tool.name}
              aria-label={tool.name}
            >
              {tool.icon}
            </button>
          ))}
        </div>
      </div>

      <div className="toolbar-section">
        <h3 className="toolbar-title">Brush Settings</h3>
        <div className="brush-settings">
          <label className="setting-label">
            Size: {brushSize}px
            <input
              type="range"
              min="1"
              max="50"
              value={brushSize}
              onChange={(e) => onBrushSizeChange(Number(e.target.value))}
              className="brush-size-slider"
            />
          </label>
          <label className="setting-label">
            Color:
            <input
              type="color"
              value={brushColor}
              onChange={(e) => onBrushColorChange(e.target.value)}
              className="color-picker"
            />
          </label>
        </div>
      </div>

      <div className="toolbar-section">
        <h3 className="toolbar-title">Actions</h3>
        <div className="action-buttons">
          <button className="action-button" onClick={onLoadImage}>
            Load Image
          </button>
          <button className="action-button" onClick={onExport}>
            Export
          </button>
          <button className="action-button danger" onClick={onClear}>
            Clear
          </button>
        </div>
      </div>
    </div>
  );
}

export default Toolbar;
