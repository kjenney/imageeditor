export interface ImageDimensions {
  width: number;
  height: number;
}

export interface Position {
  x: number;
  y: number;
}

export interface ImageLayer {
  id: string;
  name: string;
  visible: boolean;
  opacity: number;
  position: Position;
  dimensions: ImageDimensions;
}

export interface EditorState {
  currentTool: string;
  zoom: number;
  layers: ImageLayer[];
  activeLayerId: string | null;
}

export interface ToolConfig {
  id: string;
  name: string;
  icon: string;
  cursor: string;
}
