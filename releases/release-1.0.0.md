# dream_snippets 1.0.0 Release Notes

**Release Date:** not released yet (draft)

This is the first release of `dream_snippets`. It checks that each code block in the docs of a Gleam project is an exact copy of a snippet file that the project's tests compile and run. A code example in the docs can then not be wrong without a failed check.

It is the snippet check of the Dream repository, moved to its own package, with the same checks and the same messages. Dream and each Dream module use it.

## Key Highlights

- **One command**: `gleam run -m dream_snippets` checks the Markdown docs, the changelog, the release notes and the doc comments of a project
- **Byte for byte**: each `gleam` block must equal the snippet file, or the line range of it, that its badge links to
- **No setup**: the repository and the release tag come from `gleam.toml`
- **Diff blocks**: a `diff` block is checked against the real `git diff` from a release tag
- **No network access**: the check reads only the files of the project and its git history

## What's New

### Check a Project

Add the package as a dev dependency, then run the check from the project root. It prints one line for each problem, as `file:line: reason`, sorted by file and line, then a summary line. It stops with exit code 0 when there is no problem, and 1 otherwise, so a CI step fails.

The same check is a Gleam function:

#### Check a project and read what the command prints <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/doc_check_project.gleam#L5-L10"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_snippets

pub fn summary_of(directory: String) -> List(String) {
  let output = dream_snippets.output(dream_snippets.check_project(directory))
  output.standard_output
}
```

### What It Checks

- Each `gleam` block in Markdown docs and in `///` and `////` doc comments has a heading with the "tested snippet" badge directly above it
- The badge links to a snippet file in the same repository, at the tag of the `version` in `gleam.toml`
- The block is the same as the linked file, or as the line range in the link
- No Gleam code hides in a `text` or `bash` fence, or in a fence with no language
- Each `diff` block is a part of the real diff of that file from an older release tag

### Configuration

The check needs no configuration. An optional `[tools.dream_snippets]` table in `gleam.toml` sets the checked places (`markdown`, `changelog`, `release_notes`, `gleam_source`), `checked_from_version` and `badge_guide`.

- By default every changelog section and every release note is checked (`checked_from_version = "0.0.0"`). A project sets `checked_from_version` to start the check at a later version
- By default the message for a malformed badge tells the reader to copy the badge from https://hexdocs.pm/dream_snippets, where the README shows the exact heading and badge. A project sets `badge_guide` to point at its own page

#### Read the settings from the text of a `gleam.toml` <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/doc_parse_config.gleam#L5-L17"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_snippets/config.{type Config, type ConfigError}

pub fn read_config() -> Result(Config, ConfigError) {
  config.parse(
    "name = \"my_app\"
version = \"1.2.0\"
repository = { type = \"github\", user = \"me\", repo = \"my_app\" }

[tools.dream_snippets]
checked_from_version = \"1.0.0\"
",
  )
}
```

## Testing

- 130 tests run, 0 failed, 100.0% line coverage (691 of 691 lines), in about 0.5 seconds (Apple M1 Max, OTP 29, Gleam 1.19.2)

## Installing

Add the package as a dev dependency:

```bash
gleam add --dev dream_snippets
```

Then run the check from the project root:

```bash
gleam run -m dream_snippets
```

The README shows the exact heading and badge that a code block needs.

## Documentation

- [dream_snippets](https://hexdocs.pm/dream_snippets) - v1.0.0
- [README](https://github.com/TrustBound/dream_snippets/blob/main/README.md)
- [Changelog](https://github.com/TrustBound/dream_snippets/blob/main/CHANGELOG.md)

## Community

- [Discussions](https://github.com/TrustBound/dream/discussions)
- [Report Issues](https://github.com/TrustBound/dream_snippets/issues)
- [Contributing Guide](https://github.com/TrustBound/dream_snippets/blob/main/CONTRIBUTING.md)
