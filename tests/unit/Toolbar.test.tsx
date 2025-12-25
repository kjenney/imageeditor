import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { Toolbar } from '@/components/Toolbar';

describe('Toolbar', () => {
  const defaultProps = {
    currentTool: 'select' as const,
    brushSize: 5,
    brushColor: '#000000',
    onToolChange: vi.fn(),
    onBrushSizeChange: vi.fn(),
    onBrushColorChange: vi.fn(),
    onLoadImage: vi.fn(),
    onExport: vi.fn(),
    onClear: vi.fn(),
  };

  it('should render all tool sections', () => {
    render(<Toolbar {...defaultProps} />);

    expect(screen.getByText('Tools')).toBeInTheDocument();
    expect(screen.getByText('Brush Settings')).toBeInTheDocument();
    expect(screen.getByText('Actions')).toBeInTheDocument();
  });

  it('should render all tool buttons', () => {
    render(<Toolbar {...defaultProps} />);

    expect(screen.getByRole('button', { name: 'Select' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Pen' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Brush' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Eraser' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Rectangle' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Circle' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Line' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Text' })).toBeInTheDocument();
  });

  it('should call onToolChange when a tool button is clicked', () => {
    const onToolChange = vi.fn();
    render(<Toolbar {...defaultProps} onToolChange={onToolChange} />);

    fireEvent.click(screen.getByRole('button', { name: 'Pen' }));
    expect(onToolChange).toHaveBeenCalledWith('pen');
  });

  it('should highlight the active tool', () => {
    render(<Toolbar {...defaultProps} currentTool="pen" />);

    const penButton = screen.getByRole('button', { name: 'Pen' });
    expect(penButton).toHaveClass('active');
  });

  it('should call onLoadImage when Load Image button is clicked', () => {
    const onLoadImage = vi.fn();
    render(<Toolbar {...defaultProps} onLoadImage={onLoadImage} />);

    fireEvent.click(screen.getByRole('button', { name: 'Load Image' }));
    expect(onLoadImage).toHaveBeenCalled();
  });

  it('should call onExport when Export button is clicked', () => {
    const onExport = vi.fn();
    render(<Toolbar {...defaultProps} onExport={onExport} />);

    fireEvent.click(screen.getByRole('button', { name: 'Export' }));
    expect(onExport).toHaveBeenCalled();
  });

  it('should call onClear when Clear button is clicked', () => {
    const onClear = vi.fn();
    render(<Toolbar {...defaultProps} onClear={onClear} />);

    fireEvent.click(screen.getByRole('button', { name: 'Clear' }));
    expect(onClear).toHaveBeenCalled();
  });

  it('should display the current brush size', () => {
    render(<Toolbar {...defaultProps} brushSize={10} />);
    expect(screen.getByText(/Size: 10px/)).toBeInTheDocument();
  });

  it('should call onBrushSizeChange when slider is changed', () => {
    const onBrushSizeChange = vi.fn();
    render(<Toolbar {...defaultProps} onBrushSizeChange={onBrushSizeChange} />);

    const slider = screen.getByRole('slider');
    fireEvent.change(slider, { target: { value: '20' } });
    expect(onBrushSizeChange).toHaveBeenCalledWith(20);
  });
});
