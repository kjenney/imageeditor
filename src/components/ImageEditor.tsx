import { useRef, useState, useCallback, useEffect } from 'react';
import { Stage, Layer, Rect, Circle, Line, Text, Image, Transformer } from 'react-konva';
import Konva from 'konva';
import { EditorTool, ShapeConfig, DrawingLine } from '@/types';
import { generateId } from '@/utils';
import Toolbar from './Toolbar';
import AIEditPanel, { AIEditOptions } from './AIEditPanel';
import { diffusionApi } from '@/services/diffusionApi';

interface ImageEditorProps {
  width?: number;
  height?: number;
}

export function ImageEditor({ width = 800, height = 600 }: ImageEditorProps) {
  const stageRef = useRef<Konva.Stage>(null);
  const transformerRef = useRef<Konva.Transformer>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [currentTool, setCurrentTool] = useState<EditorTool>('select');
  const [brushSize, setBrushSize] = useState(5);
  const [brushColor, setBrushColor] = useState('#000000');
  const [shapes, setShapes] = useState<ShapeConfig[]>([]);
  const [lines, setLines] = useState<DrawingLine[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [isDrawing, setIsDrawing] = useState(false);
  const [currentShape, setCurrentShape] = useState<ShapeConfig | null>(null);
  const [loadedImage, setLoadedImage] = useState<HTMLImageElement | null>(null);

  // AI editing state
  const [isAIProcessing, setIsAIProcessing] = useState(false);
  const [isAIAvailable, setIsAIAvailable] = useState(false);
  const [aiError, setAiError] = useState<string | null>(null);

  // Check AI availability on mount
  useEffect(() => {
    const checkAIAvailability = async () => {
      try {
        const health = await diffusionApi.health();
        setIsAIAvailable(health.status === 'healthy');
      } catch {
        setIsAIAvailable(false);
      }
    };
    checkAIAvailability();
  }, []);

  const handleMouseDown = useCallback(
    (e: Konva.KonvaEventObject<MouseEvent>) => {
      const stage = e.target.getStage();
      if (!stage) return;

      const pos = stage.getPointerPosition();
      if (!pos) return;

      if (currentTool === 'select') {
        const clickedOnEmpty = e.target === stage;
        if (clickedOnEmpty) {
          setSelectedId(null);
        }
        return;
      }

      setIsDrawing(true);

      if (currentTool === 'pen' || currentTool === 'brush' || currentTool === 'eraser') {
        const newLine: DrawingLine = {
          id: generateId(),
          tool: currentTool,
          points: [pos.x, pos.y],
          stroke: currentTool === 'eraser' ? '#ffffff' : brushColor,
          strokeWidth: currentTool === 'brush' ? brushSize * 2 : brushSize,
        };
        setLines((prev) => [...prev, newLine]);
      } else if (currentTool === 'rectangle' || currentTool === 'circle' || currentTool === 'line') {
        const newShape: ShapeConfig = {
          id: generateId(),
          type: currentTool === 'line' ? 'line' : currentTool,
          x: pos.x,
          y: pos.y,
          width: 0,
          height: 0,
          fill: currentTool === 'line' ? undefined : brushColor,
          stroke: brushColor,
          strokeWidth: brushSize,
          draggable: true,
          points: currentTool === 'line' ? [0, 0, 0, 0] : undefined,
        };
        setCurrentShape(newShape);
      } else if (currentTool === 'text') {
        const text = prompt('Enter text:');
        if (text) {
          const newShape: ShapeConfig = {
            id: generateId(),
            type: 'text',
            x: pos.x,
            y: pos.y,
            text,
            fontSize: brushSize * 4,
            fill: brushColor,
            draggable: true,
          };
          setShapes((prev) => [...prev, newShape]);
        }
      }
    },
    [currentTool, brushColor, brushSize]
  );

  const handleMouseMove = useCallback(
    (e: Konva.KonvaEventObject<MouseEvent>) => {
      if (!isDrawing) return;

      const stage = e.target.getStage();
      if (!stage) return;

      const pos = stage.getPointerPosition();
      if (!pos) return;

      if (currentTool === 'pen' || currentTool === 'brush' || currentTool === 'eraser') {
        setLines((prev) => {
          const lastLine = prev[prev.length - 1];
          if (!lastLine) return prev;
          const newPoints = [...lastLine.points, pos.x, pos.y];
          return [...prev.slice(0, -1), { ...lastLine, points: newPoints }];
        });
      } else if (currentShape) {
        if (currentTool === 'line') {
          setCurrentShape({
            ...currentShape,
            points: [0, 0, pos.x - currentShape.x, pos.y - currentShape.y],
          });
        } else {
          setCurrentShape({
            ...currentShape,
            width: pos.x - currentShape.x,
            height: pos.y - currentShape.y,
          });
        }
      }
    },
    [isDrawing, currentTool, currentShape]
  );

  const handleMouseUp = useCallback(() => {
    if (!isDrawing) return;
    setIsDrawing(false);

    if (currentShape) {
      setShapes((prev) => [...prev, currentShape]);
      setCurrentShape(null);
    }
  }, [isDrawing, currentShape]);

  const handleShapeSelect = useCallback(
    (id: string) => {
      if (currentTool === 'select') {
        setSelectedId(id);
      }
    },
    [currentTool]
  );

  const handleTransformEnd = useCallback((e: Konva.KonvaEventObject<Event>, id: string) => {
    const node = e.target;
    setShapes((prev) =>
      prev.map((shape) =>
        shape.id === id
          ? {
              ...shape,
              x: node.x(),
              y: node.y(),
              width: node.width() * node.scaleX(),
              height: node.height() * node.scaleY(),
              rotation: node.rotation(),
              scaleX: 1,
              scaleY: 1,
            }
          : shape
      )
    );
  }, []);

  const handleDragEnd = useCallback((e: Konva.KonvaEventObject<DragEvent>, id: string) => {
    setShapes((prev) =>
      prev.map((shape) =>
        shape.id === id
          ? {
              ...shape,
              x: e.target.x(),
              y: e.target.y(),
            }
          : shape
      )
    );
  }, []);

  useEffect(() => {
    if (selectedId && transformerRef.current && stageRef.current) {
      const selectedNode = stageRef.current.findOne(`#${selectedId}`);
      if (selectedNode) {
        transformerRef.current.nodes([selectedNode]);
        transformerRef.current.getLayer()?.batchDraw();
      }
    } else if (transformerRef.current) {
      transformerRef.current.nodes([]);
    }
  }, [selectedId]);

  const handleLoadImage = useCallback(() => {
    fileInputRef.current?.click();
  }, []);

  const handleFileChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (event) => {
      const img = new window.Image();
      img.onload = () => {
        setLoadedImage(img);
      };
      img.src = event.target?.result as string;
    };
    reader.readAsDataURL(file);
  }, []);

  const handleExport = useCallback(() => {
    if (!stageRef.current) return;
    const dataURL = stageRef.current.toDataURL({ pixelRatio: 2 });
    const link = document.createElement('a');
    link.download = 'image-editor-export.png';
    link.href = dataURL;
    link.click();
  }, []);

  const handleClear = useCallback(() => {
    if (confirm('Are you sure you want to clear the canvas?')) {
      setShapes([]);
      setLines([]);
      setLoadedImage(null);
      setSelectedId(null);
    }
  }, []);

  const handleAIEdit = useCallback(
    async (prompt: string, options: AIEditOptions) => {
      if (!stageRef.current) return;

      setIsAIProcessing(true);
      setAiError(null);

      try {
        // Export current canvas to blob
        const dataURL = stageRef.current.toDataURL({ pixelRatio: 1 });
        const base64Data = dataURL.split(',')[1] || '';

        if (!base64Data) {
          throw new Error('Failed to export canvas image');
        }

        // Send to AI API
        const resultBase64 = await diffusionApi.editImageBase64(base64Data, {
          prompt,
          negativePrompt: options.negativePrompt,
          numInferenceSteps: options.numInferenceSteps,
          seed: options.seed,
        });

        // Load the result as new image
        const img = new window.Image();
        img.onload = () => {
          // Clear existing content and set new image
          setShapes([]);
          setLines([]);
          setLoadedImage(img);
          setSelectedId(null);
        };
        img.onerror = () => {
          setAiError('Failed to load the edited image');
        };
        img.src = `data:image/png;base64,${resultBase64}`;
      } catch (error) {
        const message = error instanceof Error ? error.message : 'Unknown error occurred';
        setAiError(message);
      } finally {
        setIsAIProcessing(false);
      }
    },
    []
  );

  const getCursor = () => {
    switch (currentTool) {
      case 'select':
        return 'default';
      case 'text':
        return 'text';
      default:
        return 'crosshair';
    }
  };

  const renderShape = (shape: ShapeConfig) => {
    const commonProps = {
      id: shape.id,
      key: shape.id,
      x: shape.x,
      y: shape.y,
      draggable: shape.draggable && currentTool === 'select',
      onClick: () => handleShapeSelect(shape.id),
      onTap: () => handleShapeSelect(shape.id),
      onTransformEnd: (e: Konva.KonvaEventObject<Event>) => handleTransformEnd(e, shape.id),
      onDragEnd: (e: Konva.KonvaEventObject<DragEvent>) => handleDragEnd(e, shape.id),
    };

    switch (shape.type) {
      case 'rectangle':
        return (
          <Rect
            {...commonProps}
            width={shape.width}
            height={shape.height}
            fill={shape.fill}
            stroke={shape.stroke}
            strokeWidth={shape.strokeWidth}
            rotation={shape.rotation}
          />
        );
      case 'circle':
        return (
          <Circle
            {...commonProps}
            radius={Math.abs((shape.width || 0) / 2)}
            fill={shape.fill}
            stroke={shape.stroke}
            strokeWidth={shape.strokeWidth}
          />
        );
      case 'line':
        return (
          <Line
            {...commonProps}
            points={shape.points}
            stroke={shape.stroke}
            strokeWidth={shape.strokeWidth}
          />
        );
      case 'text':
        return (
          <Text
            {...commonProps}
            text={shape.text}
            fontSize={shape.fontSize}
            fill={shape.fill}
          />
        );
      default:
        return null;
    }
  };

  return (
    <div className="image-editor">
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        onChange={handleFileChange}
        style={{ display: 'none' }}
      />
      <div className="editor-sidebar">
        <Toolbar
          currentTool={currentTool}
          brushSize={brushSize}
          brushColor={brushColor}
          onToolChange={setCurrentTool}
          onBrushSizeChange={setBrushSize}
          onBrushColorChange={setBrushColor}
          onLoadImage={handleLoadImage}
          onExport={handleExport}
          onClear={handleClear}
        />
        <AIEditPanel
          onEdit={handleAIEdit}
          isProcessing={isAIProcessing}
          isAvailable={isAIAvailable}
          error={aiError}
        />
      </div>
      <div className="canvas-container" style={{ cursor: getCursor() }}>
        <Stage
          ref={stageRef}
          width={width}
          height={height}
          onMouseDown={handleMouseDown}
          onMouseMove={handleMouseMove}
          onMouseUp={handleMouseUp}
          onMouseLeave={handleMouseUp}
          onTouchStart={(e) => {
            const stage = e.target.getStage();
            if (stage) {
              handleMouseDown(e as unknown as Konva.KonvaEventObject<MouseEvent>);
            }
          }}
          onTouchMove={(e) => {
            handleMouseMove(e as unknown as Konva.KonvaEventObject<MouseEvent>);
          }}
          onTouchEnd={() => handleMouseUp()}
        >
          <Layer>
            {/* Background */}
            <Rect
              x={0}
              y={0}
              width={width}
              height={height}
              fill="#ffffff"
              listening={false}
            />

            {/* Loaded image */}
            {loadedImage && (
              <Image
                id="loaded-image"
                image={loadedImage}
                x={0}
                y={0}
                width={width}
                height={height}
                draggable={currentTool === 'select'}
                onClick={() => handleShapeSelect('loaded-image')}
                onTap={() => handleShapeSelect('loaded-image')}
              />
            )}

            {/* Drawing lines */}
            {lines.map((line) => (
              <Line
                key={line.id}
                points={line.points}
                stroke={line.stroke}
                strokeWidth={line.strokeWidth}
                tension={0.5}
                lineCap="round"
                lineJoin="round"
                globalCompositeOperation={
                  line.tool === 'eraser' ? 'destination-out' : 'source-over'
                }
              />
            ))}

            {/* Shapes */}
            {shapes.map(renderShape)}

            {/* Current shape being drawn */}
            {currentShape && renderShape(currentShape)}

            {/* Transformer for selected shapes */}
            <Transformer
              ref={transformerRef}
              boundBoxFunc={(oldBox, newBox) => {
                if (newBox.width < 5 || newBox.height < 5) {
                  return oldBox;
                }
                return newBox;
              }}
            />
          </Layer>
        </Stage>
      </div>
    </div>
  );
}

export default ImageEditor;
