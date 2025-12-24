# Quick Start

Get started with Image Editor in just a few minutes.

## Starting the Development Server

After [installation](installation.md), start the development server:

```bash
npm run dev
```

The application will be available at `http://localhost:5173` with hot module replacement enabled.

## Available Commands

Here are the most commonly used commands:

| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server with HMR |
| `npm run build` | Create production build |
| `npm run preview` | Preview production build locally |
| `npm run test` | Run tests in watch mode |
| `npm run lint` | Check for linting errors |

## Building for Production

Create an optimized production build:

```bash
npm run build
```

The output will be in the `dist/` directory, ready for deployment.

## Preview Production Build

Test the production build locally:

```bash
npm run preview
```

## Running Tests

Run the test suite:

```bash
# Watch mode (interactive)
npm run test

# Single run with coverage
npm run test:coverage

# With UI
npm run test:ui
```

## Next Steps

- [Features Overview](../user-guide/features.md) - Explore available features
- [Development Guide](../development/setup.md) - Set up your development environment
- [Contributing](../development/contributing.md) - Learn how to contribute
