# Image Editor

A modern, web-based image editor built with React and TypeScript.

## Features

- **Modern Tech Stack**: Built with React 18, TypeScript, and Vite
- **Layer Support**: Work with multiple image layers
- **Extensible**: Modular architecture for easy feature additions
- **Fast**: Optimized build process with code splitting

## Prerequisites

- Node.js 18.0.0 or higher
- npm 9.0.0 or higher

## Quick Start

```bash
# Clone the repository
git clone https://github.com/kjenney/imageeditor.git
cd imageeditor

# Install dependencies
npm install

# Start development server
npm run dev
```

The application will be available at `http://localhost:3000`.

## Available Scripts

| Script | Description |
|--------|-------------|
| `npm run dev` | Start development server |
| `npm run build` | Build for production |
| `npm run preview` | Preview production build |
| `npm run test` | Run tests in watch mode |
| `npm run test:coverage` | Run tests with coverage |
| `npm run lint` | Check for linting errors |
| `npm run lint:fix` | Fix linting errors |
| `npm run format` | Format code with Prettier |
| `npm run type-check` | Run TypeScript type checking |
| `npm run docs` | Generate API documentation |
| `npm run docs:watch` | Generate docs and watch for changes |
| `npm run docs:serve` | Generate and serve docs locally |

## Project Structure

```
imageeditor/
├── .github/              # GitHub configuration
│   ├── workflows/        # CI/CD workflows
│   └── ISSUE_TEMPLATE/   # Issue templates
├── docs/                 # Documentation
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
├── package.json
├── tsconfig.json
├── vite.config.ts
└── README.md
```

## Development

### Code Style

This project uses:
- **ESLint** for code linting
- **Prettier** for code formatting
- **TypeScript** for type safety

Pre-commit hooks are configured with Husky to ensure code quality.

### Testing

Tests are written using Vitest and React Testing Library:

```bash
# Run tests in watch mode
npm run test

# Run tests with coverage
npm run test:coverage

# Run tests with UI
npm run test:ui
```

### Building for Production

```bash
npm run build
```

The production build will be output to the `dist/` directory.

## Documentation

API documentation is generated using [TypeDoc](https://typedoc.org/).

### Generating Documentation

```bash
# Generate API documentation
npm run docs

# Generate and watch for changes
npm run docs:watch

# Generate and serve locally
npm run docs:serve
```

Documentation will be generated in the `docs/api/` directory.

### Using Make

A Makefile is provided for common tasks:

```bash
# Show available targets
make help

# Generate documentation
make docs

# Generate and serve docs locally
make docs-serve

# Run full pipeline (install, lint, test, build, docs)
make all
```

## CI/CD

This project uses GitHub Actions for continuous integration:

- **Linting**: ESLint and Prettier checks
- **Type Checking**: TypeScript compilation
- **Testing**: Unit and integration tests with coverage
- **Building**: Production build verification
- **Documentation**: API documentation generation with TypeDoc

## Deployment

### AWS EC2 Deployment with Terraform

This project includes Terraform configuration for deploying to AWS EC2. The infrastructure provisions a complete environment including VPC, security groups, and an EC2 instance running nginx.

**Quick Deploy:**

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

After deployment, access your application at the URL provided in the output:

```bash
terraform output app_url
```

For detailed deployment instructions, configuration options, and architecture overview, see the [Terraform Documentation](terraform/README.md).

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
