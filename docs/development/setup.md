# Development Setup

This guide covers setting up your development environment for contributing to Image Editor.

## Prerequisites

- Node.js 18.0.0+
- npm 9.0.0+
- Git
- A code editor (VS Code recommended)

## Initial Setup

1. **Fork the repository** on GitHub

2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/imageeditor.git
   cd imageeditor
   ```

3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/kjenney/imageeditor.git
   ```

4. **Install dependencies**:
   ```bash
   npm install
   ```

## Development Workflow

### Starting Development Server

```bash
npm run dev
```

This starts Vite's development server with hot module replacement at `http://localhost:5173`.

### Code Quality Tools

The project uses several tools to maintain code quality:

#### ESLint

```bash
# Check for issues
npm run lint

# Auto-fix issues
npm run lint:fix
```

#### Prettier

```bash
# Check formatting
npm run format:check

# Fix formatting
npm run format
```

#### TypeScript

```bash
# Type check without emitting
npm run type-check
```

### Pre-commit Hooks

The project uses Husky for pre-commit hooks that automatically:

- Run ESLint on staged files
- Format code with Prettier
- Ensure consistent code style

## IDE Configuration

### VS Code

Recommended extensions:

- ESLint
- Prettier
- TypeScript and JavaScript Language Features
- Tailwind CSS IntelliSense

Settings are included in the repository under `.vscode/`.

## Troubleshooting

### Common Issues

**Port already in use**

```bash
# Use a different port
npm run dev -- --port 3001
```

**Node version mismatch**

Ensure you're using Node.js 18+:

```bash
node --version
```

Consider using [nvm](https://github.com/nvm-sh/nvm) to manage Node versions.

**Dependency issues**

Try removing node_modules and reinstalling:

```bash
rm -rf node_modules package-lock.json
npm install
```
