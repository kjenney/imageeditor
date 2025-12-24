# Testing

Image Editor uses Vitest and React Testing Library for testing.

## Test Structure

```
tests/
├── unit/              # Unit tests for components and utilities
├── integration/       # Integration tests
└── setup.ts          # Test setup and configuration
```

## Running Tests

### Basic Commands

```bash
# Run tests in watch mode
npm run test

# Run tests once with coverage
npm run test:coverage

# Run tests with UI
npm run test:ui
```

### Watch Mode

Watch mode is ideal for development:

```bash
npm run test
```

Tests re-run automatically when files change.

### Coverage

Generate coverage reports:

```bash
npm run test:coverage
```

Coverage reports are generated in `coverage/` directory.

## Writing Tests

### Component Tests

```typescript
import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import MyComponent from '../src/components/MyComponent';

describe('MyComponent', () => {
  it('renders correctly', () => {
    render(<MyComponent title="Test" />);
    expect(screen.getByText('Test')).toBeInTheDocument();
  });
});
```

### Testing User Interactions

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';

describe('Button', () => {
  it('calls onClick when clicked', async () => {
    const handleClick = vi.fn();
    render(<Button onClick={handleClick}>Click me</Button>);

    await userEvent.click(screen.getByRole('button'));

    expect(handleClick).toHaveBeenCalledOnce();
  });
});
```

### Testing Hooks

```typescript
import { renderHook, act } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import useCounter from '../src/hooks/useCounter';

describe('useCounter', () => {
  it('increments counter', () => {
    const { result } = renderHook(() => useCounter());

    act(() => {
      result.current.increment();
    });

    expect(result.current.count).toBe(1);
  });
});
```

### Utility Tests

```typescript
import { describe, it, expect } from 'vitest';
import { formatDate } from '../src/utils';

describe('formatDate', () => {
  it('formats date correctly', () => {
    const date = new Date('2024-01-15');
    expect(formatDate(date)).toBe('January 15, 2024');
  });
});
```

## Best Practices

### Do

- Test behavior, not implementation
- Use semantic queries (`getByRole`, `getByLabelText`)
- Write descriptive test names
- Keep tests focused and isolated

### Don't

- Test implementation details
- Use arbitrary timeouts
- Share state between tests
- Over-mock dependencies

## Debugging Tests

### Using the UI

```bash
npm run test:ui
```

Opens an interactive UI for running and debugging tests.

### Filtering Tests

Run specific tests:

```bash
# Run tests matching a pattern
npm run test -- MyComponent

# Run a specific file
npm run test -- tests/unit/utils.test.ts
```

## Continuous Integration

Tests run automatically on:

- Every push to `main` and `develop`
- Every pull request

Coverage reports are uploaded to Codecov.
