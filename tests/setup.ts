import '@testing-library/jest-dom';
import { vi } from 'vitest';
import type { ReactNode } from 'react';

// Mock react-konva components since jsdom doesn't have canvas support
vi.mock('react-konva', () => ({
  Stage: vi.fn(({ children }: { children: ReactNode }) => children),
  Layer: vi.fn(({ children }: { children: ReactNode }) => children),
  Rect: vi.fn(() => null),
  Circle: vi.fn(() => null),
  Line: vi.fn(() => null),
  Text: vi.fn(() => null),
  Image: vi.fn(() => null),
  Transformer: vi.fn(() => null),
}));

// Mock Konva
vi.mock('konva', () => ({
  default: {
    Stage: vi.fn(),
    Layer: vi.fn(),
  },
}));

// Mock window.confirm and window.prompt for tests
Object.defineProperty(window, 'confirm', {
  writable: true,
  value: vi.fn(() => true),
});

Object.defineProperty(window, 'prompt', {
  writable: true,
  value: vi.fn(() => 'Test text'),
});
