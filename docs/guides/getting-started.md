# Getting started

This guide shows how to add dream_snippets to a Gleam project, run the check, and run it in CI.

## Install

Add the package as a dev dependency:

```bash
gleam add --dev dream_snippets
```

## Run the check

From the project root:

```bash
gleam run -m dream_snippets
```

The check prints one line for each problem, as `file:line: reason`, sorted by file and line. Then it prints a summary line:

```text
README.md:42: the badge link uses the tag 1.1.0, but this file must link at the tag 1.2.0 (the docs of my_app use the version in gleam.toml)
12 blocks and 0 diff blocks checked in 9 files, 1 problems
```

The check stops with exit code 0 when there is no problem, and 1 otherwise. The check does not use the network.

## Run the check in CI

Add a step after the tests:

```yaml
- name: Check docs snippets
  run: gleam run -m dream_snippets
```

A `diff` block needs the release tags in the clone. A shallow clone has none, so check out with `fetch-depth: 0`.

## Next steps

- [Tested code blocks](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md) shows the heading and badge forms that each code block needs.
- [Configuration](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/configuration.md) shows the settings in `gleam.toml`.
