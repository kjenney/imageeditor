import Konva from 'konva';

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
  imageData?: HTMLImageElement;
}

export interface EditorState {
  currentTool: EditorTool;
  zoom: number;
  layers: ImageLayer[];
  activeLayerId: string | null;
  stageSize: ImageDimensions;
  selectedShapeId: string | null;
  brushSize: number;
  brushColor: string;
}

export type EditorTool =
  | 'select'
  | 'pen'
  | 'brush'
  | 'eraser'
  | 'rectangle'
  | 'circle'
  | 'line'
  | 'text';

export interface ToolConfig {
  id: EditorTool;
  name: string;
  icon: string;
  cursor: string;
}

export interface ShapeConfig {
  id: string;
  type: 'rectangle' | 'circle' | 'line' | 'text' | 'image' | 'freehand';
  x: number;
  y: number;
  width?: number;
  height?: number;
  radius?: number;
  fill?: string;
  stroke?: string;
  strokeWidth?: number;
  points?: number[];
  text?: string;
  fontSize?: number;
  rotation?: number;
  scaleX?: number;
  scaleY?: number;
  draggable?: boolean;
}

export interface DrawingLine {
  id: string;
  tool: 'pen' | 'brush' | 'eraser';
  points: number[];
  stroke: string;
  strokeWidth: number;
}

export interface HistoryState {
  shapes: ShapeConfig[];
  lines: DrawingLine[];
}

export type KonvaStage = Konva.Stage;
export type KonvaLayer = Konva.Layer;
export type KonvaShape = Konva.Shape;
export type KonvaTransformer = Konva.Transformer;
