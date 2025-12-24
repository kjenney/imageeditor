# API Reference

This section documents the public APIs and interfaces of Image Editor.

## Components

### App

The main application component.

```typescript
import App from './App';

// Usage
<App />
```

## Hooks

Custom React hooks for common functionality.

### useImageEditor (Planned)

Hook for accessing the image editor context.

```typescript
const { canvas, layers, tools } = useImageEditor();
```

## Utilities

### Image Utilities

Utility functions for image manipulation.

```typescript
import { loadImage, saveImage } from './utils';

// Load an image
const image = await loadImage(file);

// Save/export image
const blob = await saveImage(canvas, 'png');
```

## Types

### Core Types

```typescript
// Layer definition
interface Layer {
  id: string;
  name: string;
  visible: boolean;
  opacity: number;
  data: ImageData;
}

// Tool definition
interface Tool {
  id: string;
  name: string;
  icon: string;
  cursor: string;
  onActivate: () => void;
  onDeactivate: () => void;
}

// Canvas state
interface CanvasState {
  width: number;
  height: number;
  zoom: number;
  pan: { x: number; y: number };
}
```

## Events

### Canvas Events

```typescript
// Layer events
onLayerAdd: (layer: Layer) => void
onLayerRemove: (layerId: string) => void
onLayerUpdate: (layer: Layer) => void

// Tool events
onToolChange: (tool: Tool) => void

// Canvas events
onZoomChange: (zoom: number) => void
onPanChange: (pan: { x: number; y: number }) => void
```

## Configuration

### Editor Options

```typescript
interface EditorOptions {
  width?: number;
  height?: number;
  backgroundColor?: string;
  gridEnabled?: boolean;
  gridSize?: number;
  snapToGrid?: boolean;
}
```

---

!!! info "Work in Progress"
    This API reference is being actively developed. More documentation will be added as features are implemented.
