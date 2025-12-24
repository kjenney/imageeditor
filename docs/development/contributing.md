# Contributing

Thank you for your interest in contributing to Image Editor!

## Code of Conduct

Please read and follow our code of conduct to ensure a welcoming environment for all contributors.

## How to Contribute

### Reporting Bugs

1. Check [existing issues](https://github.com/kjenney/imageeditor/issues) first
2. Use the [bug report template](https://github.com/kjenney/imageeditor/issues/new?template=bug_report.md)
3. Include reproduction steps
4. Add screenshots if applicable

### Suggesting Features

1. Check [existing feature requests](https://github.com/kjenney/imageeditor/issues?q=is%3Aissue+label%3Aenhancement)
2. Use the [feature request template](https://github.com/kjenney/imageeditor/issues/new?template=feature_request.md)
3. Describe the use case clearly

### Submitting Code

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Write/update tests
5. Submit a pull request

## Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 2. Make Changes

- Follow the existing code style
- Add tests for new functionality
- Update documentation as needed

### 3. Test Your Changes

```bash
# Run all checks
npm run lint
npm run type-check
npm run test
npm run build
```

### 4. Commit Your Changes

Write clear, descriptive commit messages:

```bash
git commit -m "feat: add layer opacity slider"
git commit -m "fix: correct canvas zoom calculation"
git commit -m "docs: update installation instructions"
```

Follow [Conventional Commits](https://www.conventionalcommits.org/) format:

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting)
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks

### 5. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a pull request on GitHub.

## Pull Request Guidelines

### Before Submitting

- [ ] All tests pass
- [ ] Code follows project style
- [ ] Documentation updated
- [ ] Commit messages are clear

### PR Description

Include:

- Summary of changes
- Related issue numbers
- Screenshots for UI changes
- Test plan

### Review Process

1. Automated checks run
2. Maintainer reviews code
3. Address feedback
4. Merge when approved

## Getting Help

- Open a [discussion](https://github.com/kjenney/imageeditor/discussions)
- Ask questions in issues
- Read the documentation

Thank you for contributing!
