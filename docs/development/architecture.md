# Architecture

This document describes the high-level architecture of Image Editor.

## Project Structure

```
imageeditor/
├── .github/              # GitHub configuration
│   ├── workflows/        # CI/CD workflows
│   └── ISSUE_TEMPLATE/   # Issue templates
├── docs/                 # Documentation (MkDocs)
├── public/               # Static assets
├── src/
│   ├── assets/          # Images, fonts, etc.
│   ├── components/      # React components
│   ├── hooks/           # Custom React hooks
│   ├── styles/          # CSS styles
│   ├── types/           # TypeScript types
│   ├── utils/           # Utility functions
│   ├── App.tsx          # Main App component
│   └── main.tsx         # Application entry point
├── tests/
│   ├── unit/            # Unit tests
│   └── integration/     # Integration tests
├── terraform/           # Infrastructure as Code
├── mkdocs.yml           # Documentation config
├── package.json
├── tsconfig.json
└── vite.config.ts
```

## Technology Stack

### Frontend

| Technology | Purpose |
|------------|---------|
| React 19 | UI framework |
| TypeScript | Type safety |
| Vite | Build tool and dev server |
| CSS Modules | Scoped styling |

### Testing

| Technology | Purpose |
|------------|---------|
| Vitest | Test runner |
| React Testing Library | Component testing |
| jsdom | DOM simulation |

### Code Quality

| Technology | Purpose |
|------------|---------|
| ESLint | Linting |
| Prettier | Formatting |
| Husky | Git hooks |
| lint-staged | Staged file linting |

## Design Principles

### Component Architecture

Components follow these principles:

1. **Single Responsibility** - Each component has one clear purpose
2. **Composition** - Build complex UIs from simple components
3. **Props Down, Events Up** - Unidirectional data flow

### State Management

- Local state with `useState` for component-specific state
- Context API for shared state across components
- Custom hooks for reusable stateful logic

### Code Organization

- **Feature-based structure** for components
- **Shared utilities** in `utils/`
- **Type definitions** in `types/`
- **Custom hooks** in `hooks/`

## Build Process

### Development

1. Vite starts dev server
2. TypeScript compiled on-the-fly
3. HMR for instant updates
4. ESLint runs in IDE

### Production

1. TypeScript compilation
2. Vite bundle optimization
3. Code splitting
4. Asset optimization
5. Output to `dist/`

## Extending the Application

### Adding a New Component

1. Create component in `src/components/`
2. Add types in component file or `src/types/`
3. Write tests in `tests/unit/`
4. Export from appropriate index file

### Adding a New Hook

1. Create hook in `src/hooks/`
2. Add comprehensive tests
3. Document usage in JSDoc comments
