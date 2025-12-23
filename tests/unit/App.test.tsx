import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import App from '@/App';

describe('App', () => {
  it('should render the app header', () => {
    render(<App />);
    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent('Image Editor');
  });

  it('should render the welcome message', () => {
    render(<App />);
    expect(screen.getByText(/Infrastructure foundation is ready/i)).toBeInTheDocument();
  });
});
