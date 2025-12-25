import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import App from '@/App';

describe('App', () => {
  it('should render the app header', () => {
    render(<App />);
    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent('Image Editor');
  });

  it('should render the Konva subtitle', () => {
    render(<App />);
    expect(screen.getByText(/Powered by Konva/i)).toBeInTheDocument();
  });

  it('should render the image editor component', () => {
    render(<App />);
    expect(screen.getByText(/Tools/i)).toBeInTheDocument();
    expect(screen.getByText(/Brush Settings/i)).toBeInTheDocument();
  });
});
