# dream_snippets 1.0.0 Release Notes

**Release Date:** not released yet (draft)

This is the first release of `dream_snippets`. It checks that each code block in the docs of a Gleam project is proven: each Gleam block is an exact copy of a snippet file that the project's tests compile and run, and each other block is proven in the way that fits its kind. A code example in the docs can then not be wrong without a failed check.

It is the snippet check of the Dream repository, moved to its own package, with the same checks. Dream and each Dream module use it.

## Key Highlights

- **One command**: `gleam run -m dream_snippets` checks the Markdown docs, the changelog, the release notes and the doc comments of a project
- **Byte for byte**: each `gleam` block must equal the snippet file, or the line range of it, that its badge links to
- **Every block has a proof**: file, command and output blocks are copies of files that the tests or CI use, `gleam add` and dependency lines are checked against `gleam.toml`, and illustrations are marked and counted
- **No setup**: the repository and the release tag come from `gleam.toml`
- **Diff blocks**: a `diff` block is checked against the real `git diff` from a release tag
- **Code at an older release**: an upgrade guide can show old code, and the check compares it with the file at the old tag
- **History that stays right**: release notes and changelog sections of an older release are compared with the files at their own tag, so a version bump needs no change to them
- **Guide badge**: each README example links to the guide section that shows it
- **Release notes template**: release notes must follow the one template of the Dream repositories
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
- The badge links to a snippet file in the same repository, at the tag of the release of the document: its own version for release notes and a changelog section, and the `version` in `gleam.toml` for every other document
- The block is the same as the linked file, or as the line range in the link
- Each file, command and output block is the same as the linked file of `tested_files`, or is a block of package or dependency lines that `gleam.toml` proves
- No Gleam code hides in an illustration, and no fence lacks a language
- Each `diff` block is a part of the real diff of that file from an older release tag to the release of the document
- Each block of code at an older release, in a guide or in release notes, is the same as the linked file or line range at that older tag. The tag is a release before the release of the document, in semver order. The README, the changelog and doc comments have no such block
- Each example heading in the root README has a guide badge after the tested snippet badge. It links to a heading of a guide under `docs/guides`, at the same tag, and the guide links to the same snippet file
- A heading outside the README has no guide badge
- Each checked release notes file follows the release notes template

### Every Code Block Has a Proof

The language of a fence sets the kind of its block, and `check.classify_fence` is the one place that reads it. Each kind has a proof, and a language that the check doesn't know needs one too:

- A file block, such as `yaml`, `toml`, `sql` or `dockerfile`, a command block (`bash`, `sh`, `shell`, `console`) and an output block (`text`) have a heading with the tested snippet badge. The block is the linked file or line range, byte for byte. The file is one of the `tested_files` of the project, which are `test` and `.github` by default
- A command block of only `gleam add` and `gleam deps update` lines needs no badge: each package is the project or a dependency in `gleam.toml`
- A `toml` block of only dependency lines needs no badge: it names the project with the requirement of the release of the document, as the upgrade and install blocks of release notes do
- A block such as ```` ```text illustration ```` is an illustration: nothing proves it, it must not hold Gleam code, and the summary line counts it
- A fence with no language is a problem
- The fences inside a `markdown` example document get the same checks

The summary line keeps its first part and adds the new counts after a `;`, as in `1 block and 0 diff blocks checked in 1 file, 0 problems; 0 file blocks, 1 command block and 2 output blocks checked; 0 illustration blocks`.

### Guide Badge

Each example in the root README links to the guide section that explains it. The heading of the example has the tested snippet badge, then one space and the guide badge. Both images float right, so the guide badge shows to the left of the tested snippet badge. The check makes sure that the link is at the release tag, that the guide file exists under a guide directory, that the anchor is a heading of the guide, and that the guide shows the same snippet. The anchor of a heading follows GitHub's rule, and `check.heading_anchors` gives the anchors of a document.

### Code at an Older Release

An upgrade guide shows old code next to new code. The old code does not compile on the new version, so the check proves it against git. The heading of the block has a "code at an older release" badge that links to a file at an older release tag. The check reads that file with `git show <tag>:<path>`, and the block must be the same as the file or the line range in the link. The [Tested code blocks](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md) guide shows the exact badge.

### Release Notes and Changelog Sections of Older Releases

Release notes, `releases/release-<version>.md`, and a changelog section, `## [<version>]`, belong to their own release. Their badge links use the tag of that release. While it is the `version` in `gleam.toml`, the check compares their blocks with the working tree. After the next version bump, it compares them with the files at that tag, and their diffs with `git diff <old tag> <tag> -- <path>`. So the docs of each release stay right with no change, and `checked_from_version` is only needed for releases from before the project used tested docs. The tag of an older release must be in the clone.

### Versions in Semver Order

The check orders versions as semver 2.0.0 does. A pre-release comes before its release, so an upgrade guide for `2.0.0` can show code at `2.0.0-rc.1`, and the notes of `2.0.0-rc.1` belong to an older release once `gleam.toml` says `2.0.0`.

### One Line for Each Problem

Each problem and each error is exactly one line. A control character in a file name, a value or a message, such as a line break in a TOML error, shows as `\n`, `\r`, `\t` or `\u{<hex>}`. The summary line uses the singular for a count of 1, as in `1 block and 0 diff blocks checked in 1 file, 1 problem; 0 file blocks, 0 command blocks and 0 output blocks checked; 0 illustration blocks`.

### Release Notes Template

All release notes of the Dream repositories follow one template. The check reads the title, the `**Release Date:**` line and the `##` sections of each checked release notes file. It fails when a required section is missing, when a section is not in the template, is out of order or is in the file two times, and when `## Upgrading` has no `### Migration Guide`. The [Release notes template](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/release-notes-template.md) guide shows the template.

### Configuration

The check needs no configuration. An optional `[tools.dream_snippets]` table in `gleam.toml` sets the checked places (`markdown`, `changelog`, `release_notes`, `gleam_source`), `checked_from_version`, `guides`, `tested_files`, `badge_guide` and `release_notes_guide`.

- By default every changelog section and every release note is checked (`checked_from_version = "0.0.0"`). A project sets `checked_from_version` to start the check at a later version
- By default the guide badge links to a guide under `docs/guides`. A project sets `guides` to name other directories
- By default a file, command or output block links to a file under `test` or `.github`. A project sets `tested_files` to list the files and directories that its tests and CI use
- By default the message for a malformed badge tells the reader to copy the badge from https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html, the guide that shows the exact headings and badges. A project sets `badge_guide` to point at its own page
- By default a release notes template message points at https://hexdocs.pm/dream_snippets/guides/release-notes-template.html. A project sets `release_notes_guide` to point at its own page

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

- 421 tests run, 0 failed, 100.0% line coverage (1295 of 1295 lines), in about 6.2 seconds by the test runner (`make test`, Apple M1 Max, OTP 29, Gleam 1.19.2, load average about 4 from other work)

## Installing

Add the package as a dev dependency:

```bash
gleam add --dev dream_snippets
```

Then run the check from the project root:

#### Run the check <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/scripts/check.sh#L10"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```bash
gleam run -m dream_snippets
```

The [Getting started](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/getting-started.md) guide walks through the first tested snippet, the first failure and the CI step. The [Tested code blocks](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md) guide shows the exact headings and badges that a code block needs.

## Documentation

- [dream_snippets](https://hexdocs.pm/dream_snippets) - v1.0.0
- [README](https://github.com/TrustBound/dream_snippets/blob/main/README.md)
- [Guides](https://github.com/TrustBound/dream_snippets/tree/main/docs/guides)
- [Changelog](https://github.com/TrustBound/dream_snippets/blob/main/CHANGELOG.md)

## Community

- [Discussions](https://github.com/TrustBound/dream/discussions)
- [Report Issues](https://github.com/TrustBound/dream_snippets/issues)
- [Contributing Guide](https://github.com/TrustBound/dream_snippets/blob/main/CONTRIBUTING.md)
