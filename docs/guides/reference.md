# Settings and checks reference

This page lists every setting of the check with its default, and every check it makes. The guides explain how to use them. Come here when you need the full list.

## Table of Contents

- [What the check reads from gleam.toml](#what-the-check-reads-from-gleamtoml)
- [Settings](#settings)
- [The defaults in TOML](#the-defaults-in-toml)
- [Rules for the settings](#rules-for-the-settings)
- [What the check reads](#what-the-check-reads)
- [The release of a document](#the-release-of-a-document)
- [Block kinds and their proofs](#block-kinds-and-their-proofs)
- [Checks](#checks)
- [Output and exit status](#output-and-exit-status)

## What the check reads from gleam.toml

| Field | Used for |
|:---|:---|
| `name` | The messages about a wrong tag, as in `the docs of my_app use the version in gleam.toml`. |
| `version` | The release of every document that names no release of its own (see [The release of a document](#the-release-of-a-document)): the tag that its tested snippet badges and guide badges link at, and the new tag of its diff badges. Release notes and changelog sections of an older release are compared with the files at their own tag instead. |
| `repository` | The GitHub repository that every badge links at: `user` is the owner and `repo` the name. `type` must be `github`. |
| `[dependencies]`, `[dev-dependencies]` | The keys only. A `gleam add` or `gleam deps update` line with no badge may name them and `name`. A missing table has no keys, and a value that is not a table is an error. |

## Settings

All settings go in an optional `[tools.dream_snippets]` table in `gleam.toml`. Each one is optional.

| Setting | Type | Default | What it does |
|:---|:---|:---|:---|
| `markdown` | list of paths | `["README.md", "SECURITY.md", "docs", "examples"]` | Markdown documents, and directories walked for `.md` files. The root `README.md` gets the README rules. |
| `changelog` | list of paths | `["CHANGELOG.md"]` | Changelogs. Only the text before the first section, the `## [Unreleased]` section and the sections of `checked_from_version` and later are checked. |
| `release_notes` | list of paths | `["releases"]` | Directories of `release-<version>.md` files, or single `release-<version>.md` files. Only the notes of `checked_from_version` and later are checked. |
| `gleam_source` | list of paths | `["src"]` | Directories walked for `.gleam` files, whose `///` and `////` doc comments are checked. |
| `checked_from_version` | string, a semver version such as `"1.0.0"` or `"1.0.0-rc.1"` | `"0.0.0"` | The first version whose changelog section and release notes are checked, in semver order. `0.0.0` checks every version. |
| `guides` | list of paths | `["docs/guides"]` | The directories of guides. A README guide badge links to a `.md` file under one of them, and code at an older release is allowed in them. They aren't walked. |
| `tested_files` | list of paths | `["test", ".github"]` | The files and directories that the tests or CI use. A file, command or output block links to a file that is one of them or under one of them. A path doesn't need to exist, and the list isn't walked. |
| `badge_guide` | string | `"https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html"` | Where a message about a malformed badge or a missing guide badge tells the reader to copy it from. |
| `release_notes_guide` | string | `"https://hexdocs.pm/dream_snippets/guides/release-notes-template.html"` | Where a release notes message tells the reader to read the "Release notes template" section. |

## The defaults in TOML

The same defaults, as you'd write them. The tests read this file and make sure that it gives the same settings as no table:

### The defaults <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/fixtures/settings/defaults.toml"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```toml
[tools.dream_snippets]
markdown = ["README.md", "SECURITY.md", "docs", "examples"]
changelog = ["CHANGELOG.md"]
release_notes = ["releases"]
gleam_source = ["src"]
checked_from_version = "0.0.0"
guides = ["docs/guides"]
tested_files = ["test", ".github"]
badge_guide = "https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html"
release_notes_guide = "https://hexdocs.pm/dream_snippets/guides/release-notes-template.html"
```

A project whose docs are tested from `1.1.0` on, and whose contributing guide shows the badges, sets two of them:

### Two settings <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/fixtures/settings/two_settings.toml"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```toml
[tools.dream_snippets]
checked_from_version = "1.1.0"
badge_guide = "docs/contributing.md"
```

## Rules for the settings

- A list that you set replaces the default list of its kind. It doesn't add to it.
- Each path of a `markdown`, `changelog`, `release_notes` or `gleam_source` list that you set must exist. A default path that doesn't exist is skipped.
- The check never walks the directories `build`, `deps`, `_build` and `node_modules`.
- A `release_notes` path is a directory or one file. A directory is walked for `release-<version>.md` files, and files with other names are skipped. A file path must have a name of the form `release-<version>.md`, or the check reports one problem at line 1 of that file. In both cases, the notes of a version before `checked_from_version` are skipped.
- The `tested_files` paths only say which files a file, command or output block can link to. The check can't see whether a test or CI uses a file, so this list is the project's statement that they do. Keep it to the files that they really use.
- The `guides` directories only say where a guide badge can link and where code at an older release is allowed. To check the code blocks of the guides, they must be under a `markdown` path too. The default `docs` holds `docs/guides`.
- Any other key in the table is an error. A value of the wrong type is an error.
- `badge_guide` and `release_notes_guide` are text in messages. The check doesn't read them.

## What the check reads

| Kind | Files | Rules |
|:---|:---|:---|
| Markdown | `.md` files under the `markdown` paths | Each fence, by its kind. Code at an older release only under a `guides` directory. The root `README.md` also needs a guide badge on each example with a tested snippet badge. |
| Release notes | `release-<version>.md` files under the `release_notes` paths, of `checked_from_version` and later | Each fence, code at an older release allowed, and the release notes template. |
| Changelog | The `changelog` files | Each fence of the text before the first section, the `## [Unreleased]` section and the `## [<version>]` sections of `checked_from_version` and later. |
| Gleam source | `.gleam` files under the `gleam_source` paths | Each fence in each run of `///` or `////` doc comment lines, read as Markdown. |

## The release of a document

Each document, or each changelog section, belongs to one release. The release sets the tag of its badge links and the code that its blocks are compared with.

| Document | Release | Badge links and the new tag of a diff | Code that the blocks are compared with |
|:---|:---|:---|:---|
| A guide, the README, another Markdown document, doc comments | The `version` in `gleam.toml` | That version | The working tree. A diff is `git diff <old tag> -- <path>`. |
| `release-<version>.md`, or the `## [<version>]` changelog section, of the `version` in `gleam.toml` | That version | That version | The working tree, as for a guide |
| `release-<version>.md`, or the `## [<version>]` changelog section, of an older release | Its own version | Its own version | The files at its tag (`git show <tag>:<path>`). A diff is `git diff <old tag> <tag> -- <path>`. |
| The `## [Unreleased]` section, a section with another name, the text before the first section | The `version` in `gleam.toml` | That version | The working tree |

So the docs of a release stay right after the next version bump, with no change. The tag of an older release must be in the clone. A release after the `version` in `gleam.toml` is a problem. Versions are ordered as semver 2.0.0 orders them: a pre-release such as `0.2.0-rc.1` comes before `0.2.0`, so its notes and its code at an older release belong to an older release.

## Block kinds and their proofs

`check.classify_fence` reads the kind of every fence from its info string, the text after the opening backticks or tildes. The language is the first word, in lowercase. Every check gets the kind from there, so a language that the check doesn't know is a file block, never a skipped block.

| Info string | Kind | Proof | Counted as |
|:---|:---|:---|:---|
| `gleam` | Gleam block | A heading with the tested snippet badge, or with the code at an older release badge. The block is the linked file or line range, byte for byte. | `blocks` |
| `diff` | Diff block | A heading with the tested diff badge. The block is a part of the real `git diff`. | `diff blocks` |
| `markdown`, `md` | Example document | Each fence in it is checked by its kind, with the rules and the release of the document around it. Each other line must not look like Gleam code. Its headings, links and badges without a fence are not checked, and it is not checked against the release notes template. | Its fences |
| `bash`, `sh`, `shell`, `console` | Command block | A heading with the tested snippet badge or the code at an older release badge, to a file of `tested_files`. With no badge heading: each line is blank, `gleam add` or `gleam deps update`, at least one is not blank, and each argument is a package name of `name`, `[dependencies]` or `[dev-dependencies]`, or `--dev` on a `gleam add` line. A `gleam add` line names a package. | `command blocks` |
| `text` | Output block | A heading with a badge to a file of `tested_files`, as for a command block. | `output blocks` |
| `<language> illustration`, for any language but `gleam`, `diff`, `markdown` and `md` | Illustration | None. No line may look like Gleam code. | `illustration blocks` |
| Any other language | File block | A heading with a badge to a file of `tested_files`, as for a command block. With no badge heading, a `toml` block only: the first line that is not blank is `[dependencies]` or `[dev-dependencies]`, each other line is blank, one of those two, or `<package> = "<requirement>"`, at least one requirement is there, each package is `name`, and each requirement is `>= <release> and < <next major>.0.0` for the release of the document. | `file blocks` |
| Nothing | Unlabelled | None. Always a problem. | Not counted |

A heading with a badge is any heading line, at most one blank line above the fence, with the text `alt="Tested snippet"` or `alt="Code at `. When a file or command block has one, the badge is checked, and the block is never proven by its lines instead. Only the illustration mark changes the kind: other words after the language, as in `toml title=x`, are not read.

The check can't see whether a test or CI uses a file, or whether a test compares an output file with the real output. The `tested_files` setting is the project's statement of the first, and the tests of the project are the proof of the second. [Tested code blocks](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md#step-7-show-output) shows a test that compares an output file.

## Checks

The check fails when one of these is true. Each one has its own message, and [Fix a failed check](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/fixing-check-failures.md) shows each message with its fix.

**Gleam blocks and the tested snippet badge**

- A Gleam code block has no heading with the badge directly above it, with at most one blank line between.
- The badge is not in the exact format.
- The badge links to another repository or host, or out of the repository.
- The tag in the link is not the tag of the release of the document.
- The linked file does not exist, or cannot be read.
- The line range is malformed, reversed, or past the end of the file.
- The code block is not the same as the linked file or line range. A whole-file block may leave out the `////` comment at the top of the file and the blank line after it.
- The code block uses the old `🧪 Tested source` line.

**File, command and output blocks**

- A file, command or output block has no heading with a badge directly above it, and its lines are not lines that its kind proves with no file.
- The badge links to a file that is not one of the `tested_files` paths and not under one of them.
- Every check of the tested snippet badge or the code at an older release badge above, with the linked file in place of the snippet. The README guide badge is required on a README heading with the tested snippet badge, for every kind.

**Packages and dependency lines**

- A `gleam add` or `gleam deps update` line names a package that is not `name` and not a key of `[dependencies]` or `[dev-dependencies]`.
- An argument is not a package name, or is `--dev` on a `gleam deps update` line.
- A `gleam add` line names no package.
- A `toml` dependency line names another package than `name`.
- The requirement is not `>= <release> and < <next major>.0.0` for the release of the document.

**Other fences**

- A code fence has no language.
- An illustration holds a line that looks like Gleam code.
- A `markdown` fence holds a line that looks like Gleam code outside its own fences. The fences inside it are checked like any other fence.
- A code fence has no closing fence.

**The README and the guide badge**

- A README example has no guide badge, or the guide badge is not in the exact format or place.
- The guide badge link is not a link of the repository at the release tag, is not a `.md` file under a guide directory, or has no anchor.
- The guide file does not exist, has no heading with the anchor, or does not link to the snippet of the example.
- A heading outside the README has a guide badge.

**Diff blocks**

- A `diff` block has no heading with the tested diff badge, or the badge is not in the exact format.
- The diff badge link is not a compare link of the repository, its new tag is not the tag of the release of the document, or its anchor is not the digest of the path in the block.
- The block does not start with `--- a/<path>` and `+++ b/<path>` for one safe path, or has no lines after them.
- The old tag is not in the clone, or git cannot run.
- The file has no diff between the old tag and the code of the release: the working tree, or the tag of an older release.
- A hunk header of the block is not a hunk header of the real diff, or is out of order.
- A line of the block is not in that diff at that place.

**Code at an older release**

- The badge is in the README, the changelog, a doc comment, or a Markdown document that is not a guide or release notes.
- The badge is not in the exact format, its alt text or image names another tag than its link, or the heading has another badge.
- The link points to another repository, or its tag or path has other characters than letters, digits, `.`, `_`, `-` (and `/` in a path).
- The old tag is not a release before the release of the document, or it is not in the clone.
- The linked path is not a file at the old tag, or the line range is not valid for that file.
- The code block is not the same as the linked file or line range at the old tag.

**Release notes and changelog sections of a release**

- The release is an older release, and its tag is not in the clone. Each `gleam` block with a tested snippet badge and each `diff` block reports it.
- The release is after the `version` in `gleam.toml`.

**Release notes**

- A file that a `release_notes` setting names is not named `release-<version>.md`.
- The first line is not `# <Name> <version> Release Notes`, with the version of the file name.
- There is no `**Release Date:**` line between the title and the first section.
- A `##` section is not in the template, comes after a section that the template has after it, or is in the file two times.
- A required section is missing, or both `## Upgrading` and `## Installing` are in the file, or neither is.
- The `## Upgrading` section has no `### Migration Guide`.

[Release notes template](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/release-notes-template.md#the-sections) lists the sections.

**Errors that stop the check**

- `gleam.toml` is not valid TOML, or sets a key twice.
- `gleam.toml` has no `name`, no `version`, or no `repository` with `type`, `user` and `repo`.
- The repository is not on GitHub.
- A setting is unknown, or has the wrong type, or `checked_from_version` is not a semver version.
- `[dependencies]` or `[dev-dependencies]` is not a table.
- A path that a setting names does not exist.
- A file cannot be read, or a directory cannot be listed.

## Output and exit status

| Result | Standard output | Standard error | Exit status |
|:---|:---|:---|:---|
| No problem | The summary line | Nothing | 0 |
| Problems | One `file:line: reason` line for each problem, sorted by file and line, then the summary line | Nothing | 1 |
| An error that stops the check | Nothing | One `error: <description>` line | 1 |

The summary line has the form `<n> blocks and <n> diff blocks checked in <n> files, <n> problems; <n> file blocks, <n> command blocks and <n> output blocks checked; <n> illustration blocks`, with the singular for a count of 1, as in `1 block and 0 diff blocks checked in 1 file, 1 problem; 0 file blocks, 1 command block and 0 output blocks checked; 0 illustration blocks`. `blocks` counts the `gleam` blocks. The part before the `;` has the form of earlier versions, so a tool that reads only that part, or that looks for `, 0 problems;`, reads both. Each problem and each error is exactly one line: a control character in a file name, a value or a message is shown as `\n`, `\r`, `\t` or `\u{<hex>}`. The check uses no network. It reads files from the working tree, and runs `git rev-parse`, `git diff`, `git ls-tree` and `git show` in the project root for diff blocks, code at an older release, and the release notes and changelog sections of an older release.
