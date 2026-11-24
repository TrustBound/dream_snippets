# Fix a failed check

The check failed, in CI or on your machine, and you need to know what it wants. Every message names the file and the line, says what's wrong, and often says what to do. This guide is the long form: it groups the messages by what they're about, shows each one as the check prints it, and gives the fix. Find your message by its first words, or search this page for a phrase from it.

## Table of Contents

- [What you'll build](#what-youll-build)
- [Before you start](#before-you-start)
- [Step 1: Find the place](#step-1-find-the-place)
- [Step 2: Find the message](#step-2-find-the-message)
- [The heading and the badge](#the-heading-and-the-badge)
- [The badge link](#the-badge-link)
- [The line range](#the-line-range)
- [The code](#the-code)
- [Other fences](#other-fences)
- [Blocks of other languages](#blocks-of-other-languages)
- [Packages and dependency lines](#packages-and-dependency-lines)
- [README examples and the guide badge](#readme-examples-and-the-guide-badge)
- [Diff blocks](#diff-blocks)
- [Code at an older release](#code-at-an-older-release)
- [Release notes](#release-notes)
- [Docs of an older release](#docs-of-an-older-release)
- [Errors that stop the check](#errors-that-stop-the-check)
- [Test your code](#test-your-code)
- [Common pitfalls](#common-pitfalls)
- [Where to go next](#where-to-go-next)

## What you'll build

By the end of this guide you'll have:

- A passing check again, after any message it prints.
- A sense of which file is the truth for each kind of block, so the fix goes in the right place.
- A way to catch these problems in `gleam test`, before CI does.

## Before you start

The examples use the project of the other guides, `my_app`, here at version `0.2.0` in the GitHub repository `me/my_app`, with no `[tools.dream_snippets]` settings. Your messages name your own files, versions and repository.

Run the check from the project root:

### Run the check <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/scripts/check.sh#L10"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```sh
gleam run -m dream_snippets
```

## Step 1: Find the place

The check prints one line for each problem, sorted by file and line, and a summary at the end. It stops with exit status 1 when there's at least one problem. Here it is for a guide whose snippet changed:

### A failed check <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_getting_started_step_5_changed.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
docs/guides/getting-started.md:5: the code block is not the same as test/snippets/guide_getting_started_greeting.gleam; the first difference is at line 9
1 block and 0 diff blocks checked in 3 files, 1 problem; 0 file blocks, 0 command blocks and 0 output blocks checked; 0 illustration blocks
```

The part before the second colon is the place: the file, then the line, counted from 1. For a code block, a badge above it, a diff block, or code at an older release, the line is the opening fence of the block. For a guide badge, it's the heading. For a line of a diff block, a hidden Gleam line, an old `🧪 Tested source` line, a `gleam add` line or a dependency line, it's that line. For release notes, it's the line of the section heading, or line 1 when something is missing.

Each message is exactly one line. A control character in a file name or a value, such as a line break, shows as `\n`, `\r`, `\t` or `\u{<hex>}`.

## Step 2: Find the message

The rest is the reason. Match its first words with the sections below:

| The message starts with | Section |
|:---|:---|
| `this gleam code block has no heading`, `the tested snippet badge is not`, `the old "🧪 Tested source"` | [The heading and the badge](#the-heading-and-the-badge) |
| `the badge link`, `the badge links to`, `cannot read` | [The badge link](#the-badge-link) |
| `the line anchor`, `the line range` | [The line range](#the-line-range) |
| `the code block is not the same as` | [The code](#the-code) |
| `this line looks like Gleam code`, `this code fence has no language`, `this code fence has no closing fence` | [Other fences](#other-fences) |
| `this <language> code block has no heading` for a language that is not `gleam` or `diff`, `the badge links to ... which is not under a tested_files path` | [Blocks of other languages](#blocks-of-other-languages) |
| `the package`, `the argument`, `this gleam add line`, `this dependency line`, `the requirement of` | [Packages and dependency lines](#packages-and-dependency-lines) |
| `this README example heading`, `the guide badge`, `this heading has a guide badge`, `... has no tested snippet badge that links to`, `has no "# " title line`, `this line links to a guide` | [README examples and the guide badge](#readme-examples-and-the-guide-badge) |
| `this diff block`, `the tested diff badge`, `the diff badge link`, `the compare link`, `the diff block`, `the hunk header`, `this line is not in "git diff`, `cannot run git`, `... has no changes since the tag` | [Diff blocks](#diff-blocks) |
| `the code at an older release badge`, `this heading has the code at an older release badge`, `the tag ... is not`, `which is not a file at the tag` | [Code at an older release](#code-at-an-older-release) |
| `a release notes file must be named`, or any message that ends with `see "Release notes template"` | [Release notes](#release-notes) |
| `this block is in the docs of the release`, or any message that names `the release of these release notes` or `their own release` | [Docs of an older release](#docs-of-an-older-release) |
| `error:` | [Errors that stop the check](#errors-that-stop-the-check) |

## The heading and the badge

### The heading and badge messages <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/fixing_heading_and_badge.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
docs/guides/getting-started.md:5: this gleam code block has no heading with the tested snippet badge directly above it (one blank line between is allowed)
docs/guides/getting-started.md:5: the tested snippet badge is not in the exact format; copy it from https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html
docs/guides/getting-started.md:3: the old "🧪 Tested source" line is not used now; put the tested snippet badge at the end of the heading above the code block
```

- **`has no heading with the tested snippet badge`.** The `gleam` block has no heading above it, the heading has no badge, or more than one blank line sits between them. *Fix:* put a heading with the badge directly above the fence, with at most one blank line. If the code isn't meant to be tested, it's probably not Gleam: use a `text` fence for output.
- **`the tested snippet badge is not in the exact format`.** The heading ends with something like a badge, but not the exact text. A missing `align="right"`, another image address or a missing space before `<a` all cause it. *Fix:* copy the badge from [Copy a badge](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md#copy-a-badge) and change only the link address. The address after `copy it from` is the `badge_guide` setting, so your project can point it at its own page.
- **`the old "🧪 Tested source" line`.** An earlier form of tested docs put a `🧪 Tested source` link on its own line next to the block. *Fix:* delete that line and put the tested snippet badge at the end of the heading.

## The badge link

### The badge link messages <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/fixing_badge_link.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
docs/guides/getting-started.md:5: the badge link https://github.com/someone/my_app/blob/0.2.0/test/snippets/guide_getting_started_greeting.gleam does not point at a file in https://github.com/me/my_app
docs/guides/getting-started.md:5: the badge link uses the tag 0.1.0, but this file must link at the tag 0.2.0 (the docs of my_app use the version in gleam.toml)
docs/guides/getting-started.md:5: the badge links to test/snippets/greeting.gleam, which is not a file in this repository
docs/guides/getting-started.md:5: cannot read test/snippets/guide_getting_started_greeting.gleam: Permission denied
```

- **`does not point at a file in`.** The link isn't a `https://github.com/<owner>/<repo>/blob/<tag>/<path>` link of the repository in `gleam.toml`. A fork's name, a relative path, a `tree` link or a path with `..` all cause it. *Fix:* use the full `blob` address of your repository. If the repository in the message is wrong, fix `repository` in `gleam.toml`.
- **`uses the tag 0.1.0, but this file must link at the tag 0.2.0`.** A guide, the README and a doc comment link at the tag of the `version` in `gleam.toml`, and the version changed. *Fix:* replace the tag in the badge links. A search and replace of `blob/0.1.0/` with `blob/0.2.0/` across your guides does it. Leave the release notes and the changelog sections of `0.1.0` as they are: they link at their own release (see [Docs of an older release](#docs-of-an-older-release)).
- **`which is not a file in this repository`.** The snippet file was renamed, moved or deleted. *Fix:* point the link at the file's new path, or bring the file back.
- **`cannot read`.** The file exists but can't be read, here because of its permissions. *Fix:* fix the permissions, or the problem the message names.

## The line range

### The line range messages <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/fixing_line_range.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
docs/guides/getting-started.md:5: the line anchor #L5:L9 is not #L<n> or #L<start>-L<end>
docs/guides/getting-started.md:5: the line range starts at line 9, after its end at line 5
docs/guides/getting-started.md:5: the line range ends at line 20, but the file has 16 lines
```

- **`is not #L<n> or #L<start>-L<end>`.** The anchor isn't one of GitHub's two line forms. *Fix:* write `#L5-L9` for a range and `#L5` for one line.
- **`starts at line 9, after its end at line 5`.** The numbers are swapped. *Fix:* put the smaller number first.
- **`ends at line 20, but the file has 16 lines`.** The snippet got shorter, so the range now runs past its end. *Fix:* open the snippet, find the lines the block shows, and fix both numbers in the link.

## The code

### The code messages <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/fixing_code.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
docs/guides/getting-started.md:5: the code block is not the same as test/snippets/guide_getting_started_greeting.gleam; the first difference is at line 9
docs/guides/getting-started.md:14: the code block is not the same as test/snippets/guide_getting_started_greeting.gleam#L13-L16; the first difference is at line 15
```

This is the message you'll see most. The block and the file (or the line range of it) differ, and the first difference is at the line the message names, counted in the doc, not in the snippet.

*Fix:* copy the file or the lines into the block again. The snippet is the truth, because the tests run it. If a line range now points at the wrong lines, because lines were added above them, fix the numbers in the link instead. A few differences are hard to see: a tab instead of spaces, a trailing space, a missing last line. A whole-file block may leave out only the `////` comment at the top of the file and the blank line after it.

## Other fences

### The fence messages <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/fixing_fences.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
docs/guides/usage.md:4: this line looks like Gleam code in a text illustration code fence; put Gleam code in a gleam block with the tested snippet badge
docs/guides/usage.md:8: this code fence has no language; name the language of the block and prove it, or mark it as an illustration with "```text illustration"; see https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html
docs/guides/usage.md:12: this code fence has no closing fence
```

- **`this line looks like Gleam code`.** An illustration, or an example document in a `markdown` fence, holds a line such as `import a/b`, `pub fn name(`, `use x <- ...`, `let assert ...` or `|> list.map(`. Nothing proves an illustration, so it must not hold Gleam code. *Fix:* move the code to a `gleam` block with a badge. If the line really isn't Gleam, rewrite it so it doesn't take one of these forms. [Tested code blocks](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md#step-9-keep-gleam-code-out-of-illustrations) has the full list.
- **`this code fence has no language`.** A fence with no language can't be proven, so it's always a problem. *Fix:* name the language of the block, then prove the block as its kind needs. If nothing can prove it, such as a folder tree, mark it as an illustration: ```` ```text illustration ````.
- **`this code fence has no closing fence`.** A fence opens on that line and the document ends before it closes, so everything after it would be code. *Fix:* close the fence with the same character, at least as many of them as it opened with.

## Blocks of other languages

Every code block needs a proof. A block of any language other than `gleam`, `diff` and `markdown` is a copy of a file that the tests or CI use, with the same badge as a Gleam snippet:

### The messages of blocks of other languages <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/fixing_other_blocks.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
docs/guides/deploy.md:5: this dockerfile code block has no heading with the tested snippet badge directly above it; link it to the file that it copies, or mark it as an illustration with "```dockerfile illustration"; see https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html
docs/guides/deploy.md:12: this sh code block has no heading with the tested snippet badge directly above it; link it to the script that it copies, show only "gleam add" and "gleam deps update" lines, or mark it as an illustration with "```sh illustration"; see https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html
docs/guides/deploy.md:18: this text code block has no heading with the tested snippet badge directly above it; link it to the output file that a test compares with the real output, or mark it as an illustration with "```text illustration"; see https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html
docs/guides/deploy.md:25: the badge links to docs/deploy/Dockerfile, which is not under a tested_files path (test, .github); link to a file that the tests or CI use, and add its path to tested_files in [tools.dream_snippets] in gleam.toml; see https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html
```

- **`this dockerfile code block has no heading`.** A file block: any language that isn't a command or `text`, such as `yaml`, `toml`, `sql` or `dockerfile`. *Fix:* add a heading with the tested snippet badge that links to the file the block copies, such as the Dockerfile that CI builds, with a line range if the block shows only part of it. For a `toml` block of `[dependencies]` lines, see [Packages and dependency lines](#packages-and-dependency-lines).
- **`this sh code block has no heading`.** A command block: `bash`, `sh`, `shell` or `console`. *Fix:* put the command in a script that CI or a test runs, and link the block to its line. A block of only `gleam add` and `gleam deps update` lines needs no badge.
- **`this text code block has no heading`.** An output block. *Fix:* put the output in a file, such as `test/outputs/<name>.txt`, have a test compare it with the real output, and link the block to it.
- **`which is not under a tested_files path`.** The check can't see whether a test or CI uses a file, so the project lists the files and directories that they use in the `tested_files` setting. *Fix:* link to a file that the tests or CI use. When the file is one of them, add its path, or its directory, to `tested_files` in `[tools.dream_snippets]`.

In all four, a block that nothing can prove, such as a folder tree or a placeholder form, can be marked as an illustration instead: write `illustration` after the language, as in ```` ```text illustration ````. The summary line counts illustrations, so a reviewer sees how many there are. [Tested code blocks](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md#which-proof-to-use) shows each form.

## Packages and dependency lines

Two kinds of blocks are proven with no file. A command block of only `gleam add` and `gleam deps update` lines names packages that `gleam.toml` names. A `toml` block of only `[dependencies]` or `[dev-dependencies]` lines names the package of the project, with the requirement of the release of the document:

### The package and dependency messages <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/fixing_packages.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
README.md:12: the package gleam_jsn is not my_app and not a key of [dependencies] or [dev-dependencies] in gleam.toml; name only packages that this project uses; see https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html
README.md:13: the argument my_app@1 is not a package name; a gleam add line holds package names and --dev, and a gleam deps update line holds package names; see https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html
README.md:14: this gleam add line names no package; name the packages to add; see https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html
README.md:20: this dependency line names gleam_json, but a toml block with no badge names only my_app; link the block to a file that the tests use; see https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html
README.md:21: the requirement of my_app is ">= 0.1.0 and < 1.0.0", but the docs of this release use ">= 0.2.0 and < 1.0.0"; see https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html
```

- **`the package gleam_jsn is not my_app and not a key of [dependencies] or [dev-dependencies]`.** A typo, or a package that your project doesn't use. *Fix:* fix the name. If the docs tell the reader to add a package, your project uses it too, so it's in `gleam.toml`.
- **`the argument my_app@1 is not a package name`.** The check proves only package names, and `--dev` on a `gleam add` line. *Fix:* leave out the version. `gleam add` picks the latest release, and the requirement belongs in a `toml` block.
- **`this gleam add line names no package`.** *Fix:* name the packages.
- **`this dependency line names gleam_json`.** A `toml` block with no badge shows only the package of the project, as the upgrade and install blocks of release notes do. *Fix:* for other packages, link the block to a file that the tests use.
- **`the requirement of my_app is ">= 0.1.0 and < 1.0.0"`.** The block is in the docs of `0.2.0`, so the requirement is the one that `gleam add` writes for `0.2.0`. Release notes and a changelog section use their own release. *Fix:* write the requirement that the message names.

## README examples and the guide badge

### The guide badge messages <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/fixing_guide_badge.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
README.md:5: this README example heading has no guide badge after its tested snippet badge; copy the heading from https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html
README.md:5: the guide badge is not in the exact format, or it is not directly after the tested snippet badge; copy the heading from https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html
README.md:5: the guide badge link https://hexdocs.pm/my_app/getting-started.html does not point at a file in https://github.com/me/my_app
README.md:5: the guide badge link uses the tag 0.1.0, but this file must link at the tag 0.2.0 (the docs of my_app use the version in gleam.toml)
README.md:5: the guide badge links to docs/usage.md, but it must link to a .md file under docs/guides
README.md:5: the guide badge link to docs/guides/getting-started.md has no #<anchor>, but it must name the guide section of this example
README.md:5: the guide badge links to docs/guides/greeting.md, which is not a file in this repository
README.md:5: the guide badge links to the anchor #greet-a-user, but docs/guides/getting-started.md has no heading with that anchor
README.md:5: docs/guides/getting-started.md has no tested snippet badge that links to test/snippets/guide_getting_started_greeting.gleam, but the guide of a README example must show that example
README.md:5: the guide badge must name its guide: alt="Guide: Getting started" and title="Guide: Getting started", from the "# " title line of docs/guides/getting-started.md
README.md:5: docs/guides/getting-started.md has no "# " title line outside code blocks, but the guide badge names its guide by that title
README.md:12: this line links to a guide from an example; remove it, because the guide badge on the example heading is the link to the guide
docs/guides/getting-started.md:3: this heading has a guide badge, but only README example headings have one; here the heading has only the tested snippet badge
```

- **`has no guide badge`.** Each example in the root `README.md` needs a guide badge after its tested snippet badge. *Fix:* add it, as in [Step 4 of Tested code blocks](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md#step-4-add-an-example-to-the-readme).
- **`the guide badge is not in the exact format`.** The guide badge text differs, or something other than one space sits between the two badges. *Fix:* copy the heading from [Copy a badge](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md#copy-a-badge).
- **`the guide badge link ... does not point at a file in`.** The guide badge links to HexDocs or another site. *Fix:* link to the guide file in your repository, as a `blob` link.
- **`the guide badge link uses the tag`.** As for the tested snippet badge. *Fix:* use the version in `gleam.toml`.
- **`must link to a .md file under docs/guides`.** The guide isn't in a guide directory. *Fix:* move the guide into `docs/guides`, or set `guides` to the directories that hold your guides.
- **`has no #<anchor>`.** The link names the guide but not the section. *Fix:* add `#` and the anchor of the guide heading that shows the example.
- **`the guide badge links to ..., which is not a file`.** The guide was renamed or moved. *Fix:* fix the path.
- **`has no heading with that anchor`.** Usually the last hyphen is missing: a guide heading with a badge has an anchor that ends with `-`, as in `#greet-a-user-`. *Fix:* use the anchor that `check.heading_anchors` gives for the guide.
- **`has no tested snippet badge that links to`.** The guide doesn't show the README example. *Fix:* show the same snippet file in the guide, with any line range, or link the README example to the guide that shows it.
- **`the guide badge must name its guide`.** The alt text or the title of the guide badge is not `Guide: ` and the title of the guide. The badge of an earlier version has the alt text `Guide` and no title. *Fix:* copy the expected text from the message into both the `alt` and the `title` of the badge. The title of the guide is the text of its first `# ` line.
- **`has no "# " title line`.** The guide has no title, so the badge cannot name it. *Fix:* start the guide with a `# ` title line.
- **`this line links to a guide from an example`.** A `<sub>📖 [...](...)</sub>` line under a code block links to a guide. The guide badge on the example heading is the only link from an example to its guide. *Fix:* remove the line. If the example heading has no guide badge, add one that links to the same guide.
- **`this heading has a guide badge, but only README example headings have one`.** A guide, release notes or a doc comment has a heading copied from the README. *Fix:* remove the guide badge from that heading.

## Diff blocks

### The diff block messages <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/fixing_diff_blocks.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
docs/guides/upgrading.md:19: this diff block has no heading with the tested diff badge directly above it (one blank line between is allowed)
docs/guides/upgrading.md:19: the tested diff badge is not in the exact format; copy it from https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html
docs/guides/upgrading.md:19: the diff badge link https://github.com/me/my_app/compare/0.1.0..0.2.0 is not https://github.com/me/my_app/compare/<old tag>...<new tag>#diff-<digest>
docs/guides/upgrading.md:19: the compare link ends at the tag 0.1.1, but this file must use the new tag 0.2.0 (the docs of my_app use the version in gleam.toml)
docs/guides/upgrading.md:19: the diff block does not start with "--- a/<path>" and "+++ b/<path>" for one path of letters, digits and . _ - /
docs/guides/upgrading.md:19: the diff block has no diff lines after its file header
docs/guides/upgrading.md:19: the compare link anchor is not the one for src/my_app.gleam; use #diff-dc300fec45bded4a328557d8cdb35d83594380337bd562985800e8086dc62ebd
docs/guides/upgrading.md:19: the tag 0.1.0 is not in this clone; fetch the tags with "git fetch --tags" (a shallow clone has none)
docs/guides/upgrading.md:19: cannot run git: git is not on the PATH
docs/guides/upgrading.md:19: cannot run git: git stopped with exit status 128
docs/guides/upgrading.md:19: src/my_app.gleam has no changes since the tag 0.1.0
docs/guides/upgrading.md:22: the hunk header @@ -1,4 +1,11 @@ is not a hunk header of the real diff, or it is out of order
docs/guides/upgrading.md:24: this line is not in "git diff 0.1.0 -- src/my_app.gleam" at this place; a diff block shows lines of the real diff, in order and contiguous within a hunk
```

- **`has no heading with the tested diff badge`** and **`the tested diff badge is not in the exact format`.** As for the tested snippet badge, with the diff badge. *Fix:* copy it from [Copy a badge](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md#copy-a-badge).
- **`the diff badge link ... is not .../compare/<old tag>...<new tag>#diff-<digest>`.** The link isn't a compare link of your repository with three dots and a `#diff-` anchor, or a tag has characters a tag can't have. *Fix:* write it in that form.
- **`the compare link ends at the tag 0.1.1, but this file must use the new tag 0.2.0`.** In a guide, the new tag is the version in `gleam.toml`. *Fix:* change the second tag. After a version bump, the diff of a guide changes too, so copy its lines again.
- **`does not start with "--- a/<path>" and "+++ b/<path>"`** and **`has no diff lines after its file header`.** The block needs the two file lines of the real diff first, for one path, then at least one line of the diff. *Fix:* copy the `---` and `+++` lines from `git diff <tag> -- <path>`, then the lines you want to show.
- **`the compare link anchor is not the one for`.** The `#diff-` anchor is the digest of another path. *Fix:* use the anchor the message gives.
- **`the tag ... is not in this clone`.** *Fix:* run `git fetch --tags`. In CI, check out with `fetch-depth: 0`, because a shallow clone has no tags.
- **`cannot run git`.** git isn't installed, or it failed, for example because the project isn't a git repository. *Fix:* run the check in a git clone with git on the `PATH`.
- **`has no changes since the tag`.** The file is the same in the working tree as at the old tag. *Fix:* check the old tag in the link. If the change was reverted, remove the block.
- **`the hunk header ... is not a hunk header of the real diff, or it is out of order`.** *Fix:* copy the `@@` lines from the real diff, in the order they come.
- **`this line is not in "git diff ..." at this place`.** The line isn't in the diff, or it is but not right after the line before it in the block. *Fix:* copy the lines from `git diff <tag> -- <path>` without skipping any. To skip, start a new run with the `@@` header of its hunk.

## Code at an older release

### The code at an older release messages <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/fixing_old_code.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
docs/guides/upgrading.md:7: the code at an older release badge is not in the exact format, or the tag in its alt text or image is not the tag of its link; copy it from https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html
docs/guides/upgrading.md:7: this heading has the code at an older release badge and another badge, but a heading with that badge has no other badge
docs/guides/upgrading.md:7: the tag v0.1.0~1 or the path test/snippets/guide_upgrading_greet_lucy.gleam has characters that the check does not give to git (a tag has only letters, digits and . _ -, and a path also /)
docs/guides/upgrading.md:7: the tag 0.2.0 is not a release before 0.2.0, the version in gleam.toml, so use the tested snippet badge for this code
docs/guides/upgrading.md:7: the tag 0.1.0 is not in this clone; fetch the tags with "git fetch --tags" (a shallow clone has none)
docs/guides/upgrading.md:7: the badge links to test/snippets/guide_upgrading_greet_lucy.gleam, which is not a file at the tag 0.1.0
docs/guides/upgrading.md:7: the code block is not the same as test/snippets/guide_upgrading_greet_lucy.gleam#L4 at the tag 0.1.0; the first difference is at line 8
README.md:5: the code at an older release badge is only allowed in the guides under docs/guides and in release notes, because the README, the changelog and doc comments show only code of the current version
```

- **`is not in the exact format, or the tag in its alt text or image is not the tag of its link`.** The link, the alt text `Code at <tag>` and the image address must name the same tag, with `-` written as `--` and `_` as `__` in the image address. *Fix:* copy it from [Copy a badge](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md#copy-a-badge).
- **`and another badge`.** *Fix:* remove the other badge. A heading of old code has only this one.
- **`has characters that the check does not give to git`.** The check only passes plain tags and paths to git. *Fix:* use the release tag itself and a plain path.
- **`is not a release before 0.2.0`.** The tag is the current version, a later one, or not a version at all. Versions follow semver order, so `0.2.0-rc.1` is a release before `0.2.0`. *Fix:* for current code, use the tested snippet badge. For old code, use the tag of an earlier release.
- **`is not in this clone`.** *Fix:* `git fetch --tags`, and `fetch-depth: 0` in CI.
- **`which is not a file at the tag`.** The file had another path at that release. *Fix:* find it with `git grep <text> <tag> -- .` and fix the path.
- **`the code block is not the same as ... at the tag`.** *Fix:* copy the lines from `git show <tag>:<path>` into the block.
- **`is only allowed in the guides`.** The README, the changelog and doc comments show only code of the current version. *Fix:* move the old code to a guide under a `guides` directory, or to release notes.

## Release notes

### The release notes name message <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/fixing_release_notes_name.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
releases/notes-0.2.0.md:1: a release notes file must be named "release-<version>.md", for example "release-1.2.0.md"; see "Release notes template" in https://hexdocs.pm/dream_snippets/guides/release-notes-template.html
```

This one comes when a `release_notes` setting names a single file with another name. *Fix:* rename it to `release-0.2.0.md`. Every other release notes message is about the template, and [Release notes template](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/release-notes-template.md#when-the-check-fails) shows each one with its fix.

## Docs of an older release

Release notes and a `## [<version>]` changelog section belong to their own release. When that release is older than the version in `gleam.toml`, their blocks are compared with the files at its tag, and their diffs end at its tag. These messages are about them. Here `gleam.toml` says `0.2.0`, and the notes are those of `0.1.0`:

### The messages of the docs of an older release <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/fixing_older_release.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
releases/release-0.1.0.md:11: the badge link uses the tag 0.2.0, but this file must link at the tag 0.1.0 (release notes and changelog sections link at the tag of their own release)
releases/release-0.1.0.md:11: the code block is not the same as test/snippets/guide_getting_started_greeting.gleam at the tag 0.1.0; the first difference is at line 15
releases/release-0.1.0.md:11: this block is in the docs of the release 0.1.0, so it is compared with the files at the tag 0.1.0, but that tag is not in this clone; fetch the tags with "git fetch --tags" (a shallow clone has none)
releases/release-0.1.0.md:17: the tag 0.1.0 is not a release before 0.1.0, the release of these release notes, so use the tested snippet badge for this code
releases/release-0.1.0.md:23: the compare link ends at the tag 0.2.0, but this file must use the new tag 0.1.0 (release notes and changelog sections link at the tag of their own release)
releases/release-0.1.0.md:23: src/my_app.gleam has no changes between the tags 0.0.1 and 0.1.0
releases/release-0.1.0.md:28: this line is not in "git diff 0.0.1 0.1.0 -- src/my_app.gleam" at this place; a diff block shows lines of the real diff, in order and contiguous within a hunk
releases/release-0.3.0.md:11: this block is in the docs of the release 0.3.0, which is neither 0.2.0, the version in gleam.toml, nor a release before it; set the version in gleam.toml to the release that these docs are for
```

- **`must link at the tag 0.1.0 (release notes and changelog sections link at the tag of their own release)`.** Someone changed the link to the current version. *Fix:* put the tag of the release back, here `0.1.0`.
- **`the code block is not the same as ... at the tag 0.1.0`.** The block shows code that the release didn't have. *Fix:* copy the lines from `git show 0.1.0:<path>` into the block.
- **`this block is in the docs of the release 0.1.0 ... but that tag is not in this clone`.** *Fix:* `git fetch --tags`, and `fetch-depth: 0` in CI. If the release never got its tag, tag its release commit.
- **`is not a release before 0.1.0, the release of these release notes`.** Code at an older release in the notes of `0.1.0` must come from a release before `0.1.0`. *Fix:* for the code of `0.1.0` itself, use the tested snippet badge at `0.1.0`.
- **`must use the new tag 0.1.0`**, **`has no changes between the tags`** and **`this line is not in "git diff 0.0.1 0.1.0 ..."`.** As in [Diff blocks](#diff-blocks), with the tag of the release as the new side. *Fix:* copy the lines from `git diff 0.0.1 0.1.0 -- <path>`.
- **`which is neither 0.2.0, the version in gleam.toml, nor a release before it`.** The notes or the section are for a release that `gleam.toml` doesn't name yet. *Fix:* set the version in `gleam.toml` to the release you prepare.

## Errors that stop the check

These come before any file is checked, on standard error, with exit status 1 and no summary:

### The errors that stop the check <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/fixing_errors.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
error: gleam.toml is not valid TOML: found m where value was expected
error: gleam.toml sets the key name twice
error: gleam.toml has no version = "..." line before its first [section]
error: gleam.toml has no name = "..." line before its first [section]
error: gleam.toml has no repository = { type = "github", user = "...", repo = "..." }
error: gleam.toml names a gitlab repository; the badges link at GitHub, so the repository type must be github
error: tools.dream_snippets.markdown in gleam.toml must be an array of strings, but its TOML type is String
error: tools.dream_snippets.markdown in gleam.toml must be an array of strings
error: tools.dream_snippets.guide in gleam.toml is not a setting; the settings are markdown, changelog, release_notes, gleam_source, checked_from_version, guides, badge_guide, release_notes_guide, tested_files
error: tools.dream_snippets.checked_from_version in gleam.toml is "1.0", which is not a major.minor.patch version
error: examples is set in [tools.dream_snippets] in gleam.toml, but it does not exist
error: Cannot read gleam.toml: No such file or directory
error: Cannot list docs: Permission denied
```

- **`is not valid TOML`** and **`sets the key name twice`.** `gleam` itself won't read the file either. The first came from `name = my_app`, a value with no quotes. A string with no closing quote gives `found \n where " was expected`: the `\n` is the line break that the parser found. *Fix:* fix the TOML.
- **`has no version`, `has no name`, `has no repository`.** The check needs these three to build the badge links. *Fix:* add them, with `repository = { type = "github", user = "<owner>", repo = "<repo>" }`.
- **`names a gitlab repository`.** The badges link at GitHub, so the check only works for a repository on GitHub.
- **`must be an array of strings`.** A root setting is one string, as in `markdown = "docs"`, or a list with a value that isn't a string. *Fix:* use a list of strings, `markdown = ["docs"]`.
- **`is not a setting`.** A typo in a setting name. The message lists every setting.
- **`is not a major.minor.patch version`.** *Fix:* write `checked_from_version` as a semver version, as in `"1.0.0"` or `"1.0.0-rc.1"`.
- **`is set in [tools.dream_snippets] in gleam.toml, but it does not exist`.** A path you set must exist. Only default paths may be missing. *Fix:* create the path or remove it from the setting.
- **`Cannot read`** and **`Cannot list`.** The check can't read `gleam.toml` or a file, or can't list a directory. Run it from the project root, and check the permissions.

[Settings and checks reference](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/reference.md) lists every setting with its type and default.

## Test your code

The fastest way to see these messages is in your own test run. [Use it from Gleam](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/use-from-gleam.md#step-2-fail-your-tests-when-the-docs-are-wrong) shows a one-line test that fails `gleam test` with the same lines the command prints.

Every message on this page is the real text. The tests of this guide build each problem, describe it with `check.describe_problem` as the command does, and assert the exact lines shown here.

## Common pitfalls

**Fixing the block when the snippet is wrong.** *Symptom:* the check passes, and a reader's copy of the example doesn't work. *Fix:* when the block and the snippet differ, decide which one is right. If the block is right, change the snippet and its test first, then copy.

**Many messages after a version bump.** *Symptom:* every badge of the guides and the README fails with `uses the tag`. *Fix:* one search and replace of the old tag in the `blob/<tag>/` links of those files fixes them all. Diff blocks of a guide need their new tag and their lines checked again. Release notes and changelog sections keep their own tag.

**Problems only in CI.** *Symptom:* `is not in this clone` in CI, while the check passes on your machine. *Fix:* `fetch-depth: 0` in `actions/checkout`.

**A message that points at your own page.** *Symptom:* `copy it from docs/contributing.md`. *Fix:* nothing is wrong: your project set `badge_guide` or `release_notes_guide`. Those pages should show the same forms as this package's guides.

## Where to go next

- [Tested code blocks](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md): every badge form, ready to copy.
- [Show an API change in an upgrade guide](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/upgrade-guides.md): diff blocks and code at an older release, step by step.
- [Release notes template](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/release-notes-template.md): the release notes messages.
- [Settings and checks reference](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/reference.md): the settings and the full list of checks.
- [API reference on HexDocs](https://hexdocs.pm/dream_snippets/dream_snippets/check.html#Reason): the `Reason` type, one constructor for each message.
