<div align="center">
  <img src="https://raw.githubusercontent.com/TrustBound/dream/main/ricky_and_lucy.png" alt="Ricky Moony and Lucy, a moon shaped mascot for Dream with the star shaped mascot for Gleam, each with cute cartoon eyes and a smile" width="200">

<b>Checks that every code block in a Gleam project's docs matches a tested snippet file.</b>

</div>

<br />

<div align="center">
  <a href="https://hex.pm/packages/dream_snippets">
    <img src="https://img.shields.io/hexpm/v/dream_snippets" alt="Hex Package">
  </a>
  <a href="https://github.com/TrustBound/dream_snippets/releases">
    <img src="https://img.shields.io/github/v/release/TrustBound/dream_snippets?label=Release" alt="Latest Release">
  </a>
  <a href="https://hexdocs.pm/dream_snippets">
    <img src="https://img.shields.io/badge/hex-docs-lightgreen.svg" alt="HexDocs">
  </a>
  <a href="https://github.com/TrustBound/dream_snippets/actions/workflows/ci.yml?query=branch%3Amain">
    <img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/TrustBound/dream_snippets/badges/coverage.json" alt="Coverage">
  </a>
  <a href="https://github.com/TrustBound/dream_snippets/blob/main/LICENSE.md">
    <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License">
  </a>
  <a href="https://gleam.run">
    <img src="https://img.shields.io/badge/gleam-%E2%9C%A8-ffaff3" alt="Gleam">
  </a>
</div>

<br />

# dream_snippets

A code block with no tested snippet can be wrong, and nobody finds out until a reader tries it. dream_snippets is the check that every [Dream](https://github.com/TrustBound/dream) repository runs in CI to stop that: each Gleam code block in the README, the guides and the doc comments must be a copy of a snippet file that the tests compile and run. It works in any Gleam project on GitHub.

Sent here by a "not in the exact format" message? Copy the heading and badge from the section **Write a tested code block** below for a `gleam` block, or from the section **Show a change with a diff block** for a `diff` block.

## Features

- ✅ Checks each `gleam` block in Markdown docs and in `///` and `////` doc comments
- ✅ Compares the block with the linked snippet file, or a line range of it, byte for byte
- ✅ Finds Gleam code hidden in `text`, `bash` or unlabelled fences
- ✅ Checks `diff` blocks against the real `git diff` from a release tag
- ✅ Reads the repository and the release tag from `gleam.toml`, so it needs no setup
- ✅ No network access

## Installation

```bash
gleam add --dev dream_snippets
```

## Run the check

From the project root:

```bash
gleam run -m dream_snippets
```

It prints one line for each problem, as `file:line: reason`, sorted by file and line, then a summary line:

```text
README.md:42: the badge link uses the tag 1.1.0, but this file must link at the tag 1.2.0 (the docs of my_app use the version in gleam.toml)
12 blocks and 0 diff blocks checked in 9 files, 1 problems
```

It stops with exit code 0 when there is no problem, and 1 otherwise, so a CI step fails:

```yaml
- name: Check docs snippets
  run: gleam run -m dream_snippets
```

## Write a tested code block

1. Write the code in `test/snippets/<name>.gleam`.
2. Run it from a test, so that the tests fail when the snippet breaks.
3. Copy the code into the doc.
4. Give the code block a heading, and put a "tested snippet" badge at the right of the heading. The badge links to the snippet file in your GitHub repository, at the tag of the `version` in `gleam.toml`.

```markdown
### Encode a user <a href="https://github.com/me/my_app/blob/1.2.0/test/snippets/encode_user.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
```

One blank line between the heading and the block is allowed. Use the full GitHub URL, because HexDocs and Hex show the README without the repository. For an excerpt, end the link with a GitHub line range, for example `#L8-L10`: the block then shows those lines, with the same indent. A whole-file block may leave out the `////` module comment at the top of the file and the blank line after it.

Examples in doc comments are code blocks too. Put the heading and the badge inside the comment, directly above the example.

## Show a change with a diff block

Old code does not compile on the new version, so an upgrade guide shows each change as a `diff` block: an excerpt of the real git diff of one file, from the last release tag to the working tree. The block starts with the `--- a/<path>` and `+++ b/<path>` lines. Lines with no `@@` hunk header between them must come from one hunk, in order. The heading ends with a "tested diff" badge that links to the file in GitHub's compare view. The anchor is `#diff-` and the SHA-256 hex digest of the path (`printf '%s' <path> | shasum -a 256`):

```markdown
#### Read a stream from `request.body` <a href="https://github.com/me/my_app/compare/1.1.0...1.2.0#diff-96161bd1d29b10b5817d71e3db6be67d9a8494e6ea36bc113379cb3b2743ce32"><img align="right" alt="Tested diff" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-diff-lightgreen.svg?style=flat-square"></a>
```

The check runs `git diff <old tag> -- <path>`, so it needs the release tags in the clone. A shallow clone in CI has none: check out with `fetch-depth: 0`.

## What it checks

It fails when:

- a Gleam code block has no heading with the badge directly above it
- the badge is not in the exact format shown above
- the badge links to another repository or host
- the tag in the link is not the `version` in `gleam.toml`
- the linked file does not exist, or cannot be read
- the line range is malformed, reversed, or past the end of the file
- the code block is not the same as the linked file or line range
- the code block uses the old `🧪 Tested source` line
- a code fence with another language, or with no language, holds Gleam code
- a code fence has no closing fence
- a `diff` block has no heading with the tested diff badge, or the badge is not in the exact format
- the diff badge link is not a compare link of the repository, its new tag is not the `version` in `gleam.toml`, or its anchor is not the digest of the path in the block
- the old tag is not in the clone
- the file has no diff between the old tag and the working tree, or a line of the block is not in that diff at that place

A ```` ```markdown ```` fence holds an example document: its fences are checked too, and its other lines must not look like Gleam code.

## Configuration

The check reads `name`, `version` and `repository` from `gleam.toml`. The repository must be on GitHub. Everything else has a default, and an optional `[tools.dream_snippets]` table changes it. These are the defaults:

```toml
[tools.dream_snippets]
# Markdown documents, and directories walked for .md files
markdown = ["README.md", "SECURITY.md", "docs", "examples"]
# Changelogs: only the [Unreleased] section and the sections of
# checked_from_version and later are checked
changelog = ["CHANGELOG.md"]
# Directories of release-<version>.md files: only the notes of
# checked_from_version and later are checked
release_notes = ["releases"]
# Directories walked for .gleam files, whose doc comments are checked
gleam_source = ["src"]
# The first version whose changelog section and release notes are
# checked; 0.0.0 checks every version
checked_from_version = "0.0.0"
# Where the message for a malformed badge tells the reader to copy it from
badge_guide = "https://hexdocs.pm/dream_snippets"
```

By default every changelog section and every release note is checked, and a malformed badge message points at this README on HexDocs:

```text
README.md:12: the tested snippet badge is not in the exact format; copy it from https://hexdocs.pm/dream_snippets
```

Release notes and changelog sections from before the project had tested docs show code that was right for their own version. Set `checked_from_version` to the first version with tested docs, so the check starts there. Set `badge_guide` to a page of your own that shows the badge, for example a contributing guide. A project with tested docs from 1.1.0 and its own guide sets both:

```toml
[tools.dream_snippets]
checked_from_version = "1.1.0"
badge_guide = "docs/contributing.md"
```

A list that you set replaces the default list of its kind, and each of its paths must exist. A default path that does not exist is skipped. The directories `build`, `deps`, `_build` and `node_modules` are never walked. Any other key in the table is an error.

## Use it from Gleam

The checks are pure functions in `dream_snippets/check`. They get the snippet files and git through a `CheckContext`, so you can check a document with any files and history.

### Check one document <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/readme_check_markdown.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_snippets/check.{
  type Report, CheckContext, GitHubRepository, Project, Version,
}
import dream_snippets/git
import simplifile

pub fn check_guide(guide: String) -> Report {
  let project =
    Project(
      name: "my_app",
      version: "1.2.0",
      repository: GitHubRepository(owner: "me", name: "my_app"),
      badge_guide: "CONTRIBUTING.md",
    )
  let context =
    CheckContext(
      project:,
      checked_from_version: Version(1, 0, 0),
      read_source: simplifile.read,
      tag_exists: fn(_tag) { Error(git.GitNotFound) },
      diff_from_tag: fn(_tag, _path) { Error(git.GitNotFound) },
    )
  check.check_markdown("docs/guide.md", guide, context)
}
```

`dream_snippets.check_project` checks a whole project in a directory, and `dream_snippets.output` turns its result into the lines that the command prints. See the [API docs](https://hexdocs.pm/dream_snippets) for the rest.

## Design Principles

dream_snippets follows Dream's [design principles](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/reference/design-principles.md) and [contributing guide](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/contributing/contributing.md).

## About Dream

This package was first built inside the [Dream](https://github.com/TrustBound/dream) web toolkit, as the check behind its tested docs. It is standalone and can be used in any Gleam project. It follows Dream's design principles and will be maintained as part of the Dream ecosystem.

## Contributing

See the [Contributing Guide](https://github.com/TrustBound/dream_snippets/blob/main/CONTRIBUTING.md) for guidelines.

---

## License

MIT — see [LICENSE.md](https://github.com/TrustBound/dream_snippets/blob/main/LICENSE.md)

---

<div align="center">
  <sub>Built in Gleam, on the BEAM, by the <a href="https://github.com/trustbound/dream">Dream Team</a> ❤️</sub>
</div>
