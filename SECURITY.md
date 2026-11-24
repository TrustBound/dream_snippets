# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | ✅ Active support  |

## What dream_snippets Is Responsible For

dream_snippets is a development tool that a project runs from its own root, in CI or on a contributor's machine. It:
- **Reads files** - `gleam.toml`, the docs in the checked roots, and the snippet files that the badges link to
- **Runs git** - `git rev-parse` and `git diff` for the `diff` blocks, started directly with no shell between
- **Prints a report** - one line for each problem, then a summary

It never uses the network, and it never writes a file.

This means dream_snippets's security surface is small:
- A badge link that makes it read a file outside the repository (a path with `..` is rejected before any read)
- A tag or path in a `diff` block that git could read as an option (only letters, digits and `. _ - /` are passed, and the path comes after `--`)
- Resource exhaustion on a very large document

## What You're Responsible For

Your project handles:
- **What is in your docs** - dream_snippets checks code blocks, not what the code does
- **Your CI** - who can change the workflows that run the check
- **Your git clone** - the tags and history that the `diff` blocks are checked against

## Reporting a Vulnerability

**Do not report security vulnerabilities through public GitHub issues.**

Email: **engineering@trustbound.ai**

### What to Include

- **Type of vulnerability** (e.g., a file read outside the repository)
- **Location** in dream_snippets's code (file/function)
- **Steps to reproduce** with minimal example
- **Impact** - What can an attacker do?
- **Proof-of-concept** if you have one

Focus on vulnerabilities in **dream_snippets's code**, not in your project.

### What to Expect

1. **Acknowledgment** within 48 hours
2. **Assessment** within 7 days
3. **Fix** coordinated with you on timing
4. **Release** with security advisory
5. **Credit** in the advisory (if desired)

## Security in dream_snippets

### Type Safety

Gleam's type system prevents many vulnerabilities:
- ✅ No null pointer exceptions
- ✅ No buffer overflows
- ✅ Exhaustive pattern matching
- ✅ Immutable data structures

## Dependencies

dream_snippets's dependencies:
- **simplifile** - File reads
- **tom** - Reads `gleam.toml`
- **Gleam stdlib** - Type-safe, battle-tested
- **BEAM/OTP** - 30+ years of production use

We monitor dependencies and update promptly for security issues.

## Questions?

- **Security questions**: engineering@trustbound.ai
- **Non-security issues**: [GitHub Issues](https://github.com/TrustBound/dream_snippets/issues)
- **General discussion**: [GitHub Discussions](https://github.com/TrustBound/dream/discussions)

---

**Remember:** dream_snippets is a development tool. It checks your docs. You decide what goes into them.
