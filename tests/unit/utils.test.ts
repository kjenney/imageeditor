import { describe, it, expect, vi } from 'vitest';
import { generateId, clamp, debounce } from '@/utils';

describe('generateId', () => {
  it('should generate a string id', () => {
    const id = generateId();
    expect(typeof id).toBe('string');
    expect(id.length).toBeGreaterThan(0);
  });

  it('should generate unique ids', () => {
    const id1 = generateId();
    const id2 = generateId();
    expect(id1).not.toBe(id2);
  });
});

describe('clamp', () => {
  it('should return the value if within range', () => {
    expect(clamp(5, 0, 10)).toBe(5);
  });

  it('should return min if value is below range', () => {
    expect(clamp(-5, 0, 10)).toBe(0);
  });

  it('should return max if value is above range', () => {
    expect(clamp(15, 0, 10)).toBe(10);
  });

  it('should handle edge cases', () => {
    expect(clamp(0, 0, 10)).toBe(0);
    expect(clamp(10, 0, 10)).toBe(10);
  });
});

describe('debounce', () => {
  it('should debounce function calls', () => {
    vi.useFakeTimers();
    const fn = vi.fn();
    const debounced = debounce(fn, 100);

    debounced();
    debounced();
    debounced();

    expect(fn).not.toHaveBeenCalled();

    vi.advanceTimersByTime(100);

    expect(fn).toHaveBeenCalledTimes(1);

    vi.useRealTimers();
  });
});
