# Makefile for Image Editor
# Documentation and build automation

.PHONY: help install docs docs-watch docs-serve docs-clean build test lint format clean all

# Default target
help:
	@echo "Image Editor - Available targets:"
	@echo ""
	@echo "  install      Install project dependencies"
	@echo "  docs         Generate API documentation"
	@echo "  docs-watch   Generate docs and watch for changes"
	@echo "  docs-serve   Generate docs and serve locally"
	@echo "  docs-clean   Remove generated documentation"
	@echo "  build        Build the application for production"
	@echo "  test         Run tests"
	@echo "  test-cov     Run tests with coverage"
	@echo "  lint         Run linting"
	@echo "  format       Format code with Prettier"
	@echo "  clean        Remove build artifacts and generated files"
	@echo "  all          Install, lint, test, build, and generate docs"
	@echo ""

# Install dependencies
install:
	npm ci

# Documentation targets
docs:
	npm run docs

docs-watch:
	npm run docs:watch

docs-serve:
	npm run docs:serve

docs-clean:
	rm -rf docs/api

# Build targets
build:
	npm run build

# Test targets
test:
	npm run test

test-cov:
	npm run test:coverage

# Code quality targets
lint:
	npm run lint

lint-fix:
	npm run lint:fix

format:
	npm run format

format-check:
	npm run format:check

type-check:
	npm run type-check

# Clean targets
clean:
	rm -rf dist node_modules coverage docs/api .cache

# Full build pipeline
all: install lint type-check test build docs
	@echo "Full build pipeline completed successfully!"
