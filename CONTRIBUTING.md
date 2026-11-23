# Contributing to dream_snippets

Thank you for your interest in contributing to dream_snippets! We're excited to have you here.

dream_snippets is part of the [Dream](https://github.com/TrustBound/dream) family. It follows Dream's coding and testing standards. The standards live in the Dream repository.

## Quick Links

📖 **[Full Contributing Guide](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/contributing/contributing.md)** - Detailed contribution guidelines  
🧪 **[Testing Guide](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/contributing/testing.md)** - How Dream projects write tests  
✍️ **[Tone Guide](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/contributing/tone-guide.md)** - Documentation writing style  
🤝 **[Code of Conduct](https://github.com/TrustBound/dream_snippets/blob/main/CODE_OF_CONDUCT.md)** - Community standards  
🔒 **[Security Policy](https://github.com/TrustBound/dream_snippets/blob/main/SECURITY.md)** - Reporting security vulnerabilities

## Quick Start for Contributors

### Prerequisites

- Gleam 1.19.2 or later
- Erlang/OTP 27 or later, with the JIT (the tests measure line coverage)

### Development Setup

1. **Fork and clone:**
   ```bash
   git clone https://github.com/YOUR-USERNAME/dream_snippets.git
   cd dream_snippets
   ```

2. **Run tests:**
   ```bash
   make test                # All tests, with line coverage
   ```

3. **Make your changes:**
   - Write code following Dream's [design principles](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/reference/design-principles.md)
   - Add tests for new functionality
   - Update documentation as needed

4. **Format and verify:**
   ```bash
   gleam format             # Format code
   make check               # Format check, build, tests, docs build and snippet check
   ```

5. **Submit a pull request:**
   - Clear description of changes
   - Reference any related issues
   - Ensure CI passes

## What Can I Contribute?

### 🐛 Bug Reports
Found a bug? [Open an issue](https://github.com/TrustBound/dream_snippets/issues/new) with:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Your environment (Gleam version, OS, etc.)

### 💡 Feature Requests
Have an idea? [Open an issue](https://github.com/TrustBound/dream_snippets/issues/new) with:
- Clear use case
- Proposed API or behavior
- Why this fits Dream's philosophy

### 📝 Documentation
Documentation improvements are always welcome:
- Fix typos or unclear explanations
- Add examples
- Improve guides

### 🔧 Code Contributions
- Fix bugs
- Implement approved features
- Improve performance
- Add tests

## Code Standards

dream_snippets follows Dream's strict coding standards. Please read:
- **[Design Principles](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/reference/design-principles.md)** - The "why" behind Dream
- **[Naming Conventions](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/reference/naming-conventions.md)** - Code style rules

Key principles:
- **No magic** - Everything explicit
- **No closures** - All dependencies are parameters
- **Full words** - No abbreviations (except standard ones)
- **100% test coverage** - For `src/` code
- **Black box testing** - Test public interfaces only

## Development Workflow

1. **Create a branch:**
   ```bash
   git checkout -b feature/my-feature
   # or
   git checkout -b fix/issue-123
   ```

2. **Make focused commits:**
   ```bash
   git commit -m "Check fences in nested lists"
   ```

3. **Keep your fork updated:**
   ```bash
   git remote add upstream https://github.com/TrustBound/dream_snippets.git
   git fetch upstream
   git rebase upstream/main
   ```

4. **Push and create PR:**
   ```bash
   git push origin feature/my-feature
   ```

## Testing Requirements

All contributions must include tests:

- **Unit tests** - Fast, isolated, deterministic
- **100% coverage** - For all code in `src/`. `gleam test` fails below 100%.

See the [Testing Guide](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/contributing/testing.md) for details.

## Documentation Requirements

Update documentation for:
- New features (HexDocs + README)
- API changes (update all references)
- Breaking changes (migration guide)

Every Gleam code block in the README and in doc comments comes from a tested snippet in `test/snippets/`. See "Code Blocks in READMEs and Guides" in the [Full Contributing Guide](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/contributing/contributing.md).

dream_snippets checks its own docs. Run the check from the repository root:

```bash
make check-snippets      # Same as gleam run -m dream_snippets
```

## Review Process

1. **Automated checks:**
   - Code formatting (`gleam format --check src test`)
   - Unit tests and 100% line coverage
   - Documentation build
   - Snippet check (`gleam run -m dream_snippets`)
   - No compiler warnings

2. **Manual review:**
   - Code quality
   - Tests coverage
   - Documentation
   - Fits Dream's philosophy

3. **Maintainer approval:**
   - At least one maintainer approval required
   - May request changes or clarification

## Getting Help

- **Questions?** [Open a discussion](https://github.com/TrustBound/dream/discussions)
- **Stuck?** Comment on your PR or issue
- **Security issue?** See [SECURITY.md](https://github.com/TrustBound/dream_snippets/blob/main/SECURITY.md)

## Recognition

All contributors are recognized in our documentation and release notes. Thank you for making dream_snippets better! 🎉

## About Dream

Dream was created by [TrustBound](https://trustbound.ai), an AI security platform, to build our production SaaS. We needed a type-safe web toolkit that was explicit, composable, and ran on the BEAM for massive concurrency.

We built Dream, used it to build TrustBound, and open-sourced it under MIT license so others could benefit.

Dream is community-driven. TrustBound funds development, but contributions come from everyone. All decisions happen in public issues and discussions.

---

**Read more:** [Full Contributing Guide](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/contributing/contributing.md)
