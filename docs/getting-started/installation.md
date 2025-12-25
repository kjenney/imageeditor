# Installation

This guide covers how to install and set up Image Editor for local development.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js** 18.0.0 or higher
- **npm** 9.0.0 or higher
- **Git** for version control

You can verify your installations with:

```bash
node --version
npm --version
git --version
```

## Clone the Repository

```bash
git clone https://github.com/kjenney/imageeditor.git
cd imageeditor
```

## Install Dependencies

Install all project dependencies using npm:

```bash
npm install
```

This will install:

- React and React DOM
- TypeScript compiler
- Vite build tool
- Testing libraries (Vitest, Testing Library)
- Linting tools (ESLint, Prettier)
- And other development dependencies

## Verify Installation

Run the development server to verify everything is working:

```bash
npm run dev
```

The application should now be available at `http://localhost:5173`.

## Next Steps

- [Quick Start Guide](quick-start.md) - Learn the basics
- [Development Setup](../development/setup.md) - Configure your development environment
- [Architecture Overview](../development/architecture.md) - Understand the codebase
