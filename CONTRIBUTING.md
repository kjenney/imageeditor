# Contributing to Image Editor

Thank you for your interest in contributing to Image Editor! This document provides guidelines and information for contributors.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/imageeditor.git`
3. Install dependencies: `npm install`
4. Create a feature branch: `git checkout -b feature/your-feature-name`

## Development Workflow

### Running the Development Server

```bash
npm run dev
```

### Running Tests

```bash
npm run test          # Run tests in watch mode
npm run test:coverage # Run tests with coverage report
```

### Linting and Formatting

```bash
npm run lint          # Check for linting errors
npm run lint:fix      # Fix linting errors
npm run format        # Format code with Prettier
npm run format:check  # Check code formatting
```

### Type Checking

```bash
npm run type-check
```

## Code Style

- We use TypeScript for type safety
- ESLint for linting
- Prettier for code formatting
- Follow the existing code patterns and conventions

## Commit Messages

We follow conventional commit messages:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Adding or updating tests
- `chore:` Maintenance tasks

Example: `feat: add crop tool functionality`

## Pull Request Process

1. Ensure all tests pass
2. Update documentation if needed
3. Add tests for new functionality
4. Ensure your code follows the project's code style
5. Create a pull request with a clear description

## Reporting Issues

When reporting issues, please include:

- A clear description of the problem
- Steps to reproduce
- Expected behavior
- Actual behavior
- Browser and OS information
- Screenshots if applicable

## Questions?

Feel free to open an issue for any questions or concerns.
