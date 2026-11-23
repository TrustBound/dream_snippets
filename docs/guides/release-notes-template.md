# Release notes template

All release notes of the Dream repositories follow one template, so a reader finds the same section in the same place for every package, and the check enforces it. A message that ends with `see "Release notes template"` sends you here. The rules and the list of sections are right below. After them, this guide writes a complete release notes file step by step, shows what the check prints for each mistake, and shows how to test your notes.

## Table of Contents

- [The template](#the-template)
- [The sections](#the-sections)
- [What you'll build](#what-youll-build)
- [Before you start](#before-you-start)
- [Upgrading or Installing](#upgrading-or-installing)
- [Step 1: Name the file](#step-1-name-the-file)
- [Step 2: Write the title and the release date](#step-2-write-the-title-and-the-release-date)
- [Step 3: Add the sections in order](#step-3-add-the-sections-in-order)
- [A complete release notes file](#a-complete-release-notes-file)
- [Step 4: Run the check](#step-4-run-the-check)
- [When the check fails](#when-the-check-fails)
- [Test your code](#test-your-code)
- [Common pitfalls](#common-pitfalls)
- [Where to go next](#where-to-go-next)

## The template

The check reads each release notes file of `checked_from_version` and later. It reads headings outside code fences only, and it ignores HTML after a heading, such as a badge.

1. The file name is `release-<version>.md`, for example `release-3.0.0.md`.
2. The first line is `# <Name> <version> Release Notes`. `<version>` is the version in the file name, so `releases/release-3.0.0.md` has `3.0.0`. `<Name>` is any text, for example `Dream`, `dream_json` or `Dream Test`.
3. A line that starts with `**Release Date:**` comes after the title and before the first `##` section.
4. The `##` sections are only those in the list of sections below, each one time at most, in the order of the list.
5. The `Upgrading` section has a `### Migration Guide` heading.

## The sections

Each item gives the text of a `##` heading and tells if the section is required or optional. A test of this package compares this list with the template in the code.

1. `Key Highlights`: required
2. `What's New`: required
3. `Deprecated`: optional
4. `Removed`: optional
5. `Bug Fixes`: optional
6. `Known Limits`: optional
7. `Testing`: required
8. `Upgrading` or `Installing`: required, exactly one of the two, and `Installing` is for a first release
9. `Acknowledgements`: optional
10. `Documentation`: required
11. `Community`: required

## What you'll build

In this guide you'll:

- Write the release notes of `my_app` `0.2.0`, which pass the check.
- See the exact message for each way release notes can break the template.
- Add a test that checks your release notes in `gleam test`.

## Before you start

You need the package as a dev dependency, and a `releases/` directory at the project root. The check reads `releases/` with no settings.

```sh
gleam add --dev dream_snippets
mkdir -p releases
```

The examples use the project `my_app` at version `0.2.0`, in the GitHub repository `me/my_app`.

## Upgrading or Installing

Every release notes file has one of these two sections, never both:

| Your situation | Use | Why |
|:---|:---|:---|
| The first release of the package | `## Installing` | There is nothing to upgrade from. Show how to add the package and run it. |
| Any later release | `## Upgrading` with `### Migration Guide` | A reader on the old version needs the steps to move, even when the steps are "nothing to change". |

The `Upgrading` section can show the old code next to the new code. Release notes may hold code at an older release, as [Show an API change in an upgrade guide](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/upgrade-guides.md) explains.

## Step 1: Name the file

Name the file after the version: `releases/release-0.2.0.md`. The check reads the version from the name, and it uses that version for three things:

- The title must name it.
- `checked_from_version` decides whether the file is checked at all.
- The code blocks of the file belong to that release. Their badges link at the tag `0.2.0`. While `gleam.toml` says `0.2.0`, the check compares them with your working tree. After the next version bump, it compares them with the files at the tag `0.2.0`, so the notes stay right with no change.

In a directory, the check skips a file with another name. A file that a `release_notes` setting names on its own must have this form, or the check reports it.

## Step 2: Write the title and the release date

The first line is the title, `# my_app 0.2.0 Release Notes`. The name before the version can be any text, so `# My App 0.2.0 Release Notes` works too. The version must be the one in the file name.

Somewhere after the title and before the first `##` section, one line starts with `**Release Date:**`. What follows is free text, so a draft can say `**Release Date:** not released yet (draft)`. Text between the title and the first section is fine. It's a good place for one paragraph that says what the release is about.

## Step 3: Add the sections in order

Add the `##` sections in the order of [the list](#the-sections). Leave out the optional sections you don't need. Each section can have any content: `###` headings, lists, tables, and tested code blocks with their badges. The check examines the code blocks of release notes like those of a guide, so each `gleam` block needs a tested snippet badge or a code at an older release badge.

A `##` heading may end with HTML, such as a badge. The check compares only the text before it. A heading inside a code fence doesn't count as a section, so an example document in a ```` ```markdown ```` fence can show any heading.

## A complete release notes file

Here's the whole file for `my_app` `0.2.0`. It has every required section and no optional one:

```markdown
# my_app 0.2.0 Release Notes

**Release Date:** 2026-11-23

`greeting` now takes a style, so you can greet people formally.

## Key Highlights

- **Greeting styles**: `greeting(name, Formal)` says "Hello, Lucy."

## What's New

### Greeting styles

`greeting` takes a `Style` as its second argument: `Casual` or `Formal`.

## Testing

- 42 tests run, 0 failed

## Upgrading

### Migration Guide

Add a style to each call of `greeting`: `Casual` for "Hi, Lucy!", or `Formal` for "Hello, Lucy.".

## Documentation

- [my_app](https://hexdocs.pm/my_app) - v0.2.0

## Community

- [Report Issues](https://github.com/me/my_app/issues)
```

## Step 4: Run the check

```sh
gleam run -m dream_snippets
```

```text
0 blocks and 0 diff blocks checked in 2 files, 0 problems
```

The two files are `releases/release-0.2.0.md` and `src/my_app.gleam`. The template check adds no blocks to the count, but each mistake is a problem line, as the next section shows.

## When the check fails

Each example below is the complete file above with one mistake, and the output of the check. Every message ends with a pointer to this guide. The address is the `release_notes_guide` setting, so a project can point it at its own page with a "Release notes template" section.

**The title names another version.** The title says `0.1.0` in `release-0.2.0.md`. *Fix:* use the version of the file name.

```text
releases/release-0.2.0.md:1: the first line is "# my_app 0.1.0 Release Notes", but the template wants the title "# <Name> 0.2.0 Release Notes"; see "Release notes template" in https://hexdocs.pm/dream_snippets/guides/release-notes-template.html
0 blocks and 0 diff blocks checked in 2 files, 1 problem
```

**No release date.** *Fix:* add a `**Release Date:**` line before the first section.

```text
releases/release-0.2.0.md:1: there is no line that starts with "**Release Date:**" between the title and the first section, but the template wants one there; see "Release notes template" in https://hexdocs.pm/dream_snippets/guides/release-notes-template.html
0 blocks and 0 diff blocks checked in 2 files, 1 problem
```

**A section that isn't in the template.** *Fix:* make it a `###` heading inside a template section, or drop it.

```text
releases/release-0.2.0.md:17: "## Files changed" is not a section of the release notes template; see "Release notes template" in https://hexdocs.pm/dream_snippets/guides/release-notes-template.html
0 blocks and 0 diff blocks checked in 2 files, 1 problem
```

**A section out of order.** Here `Testing` comes after `Upgrading`. *Fix:* move it to its place in the list.

```text
releases/release-0.2.0.md:26: "## Testing" comes after "## Upgrading", but the template has it before "## Upgrading"; see "Release notes template" in https://hexdocs.pm/dream_snippets/guides/release-notes-template.html
0 blocks and 0 diff blocks checked in 2 files, 1 problem
```

**A section two times.** *Fix:* merge the two into one.

```text
releases/release-0.2.0.md:17: "## What's New" is in the file again (first at line 11), but the template has each section one time at most; see "Release notes template" in https://hexdocs.pm/dream_snippets/guides/release-notes-template.html
0 blocks and 0 diff blocks checked in 2 files, 1 problem
```

**Both `Upgrading` and `Installing`.** *Fix:* keep `Upgrading` for a later release, or `Installing` for the first one.

```text
releases/release-0.2.0.md:27: "## Upgrading" and "## Installing" are both in the file, but the template allows only one of them; see "Release notes template" in https://hexdocs.pm/dream_snippets/guides/release-notes-template.html
0 blocks and 0 diff blocks checked in 2 files, 1 problem
```

**A required section is missing.** Here `Testing` is gone. *Fix:* add it, even with one line.

```text
releases/release-0.2.0.md:1: the section "## Testing" is missing, but the template requires it; see "Release notes template" in https://hexdocs.pm/dream_snippets/guides/release-notes-template.html
0 blocks and 0 diff blocks checked in 2 files, 1 problem
```

**Neither `Upgrading` nor `Installing`.** *Fix:* add the one that fits, as in [Upgrading or Installing](#upgrading-or-installing).

```text
releases/release-0.2.0.md:1: neither "## Upgrading" nor "## Installing" is in the file, but the template requires one of them; see "Release notes template" in https://hexdocs.pm/dream_snippets/guides/release-notes-template.html
0 blocks and 0 diff blocks checked in 2 files, 1 problem
```

**`Upgrading` without `### Migration Guide`.** *Fix:* add the heading inside `Upgrading`, before the next `##` section.

```text
releases/release-0.2.0.md:21: "## Upgrading" has no "### Migration Guide", but the template requires it in that section; see "Release notes template" in https://hexdocs.pm/dream_snippets/guides/release-notes-template.html
0 blocks and 0 diff blocks checked in 2 files, 1 problem
```

A missing part is reported at line 1. A section in the wrong place is reported at its heading. A file named on its own in a `release_notes` setting, with a name that isn't `release-<version>.md`, gets one message at line 1, as [Fix a failed check](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/fixing-check-failures.md#release-notes) shows.

## Test your code

The command checks your release notes with the rest of the docs. If you also want a test that names the file, `check.check_release_notes_template` checks the template of one file and needs nothing but its path and text:

### Check one release notes file in a test <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/guide_release_notes_template_test.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_snippets/check.{type Problem}
import gleam/result
import simplifile

/// The template problems of one release notes file.
pub fn template_problems(
  path: String,
) -> Result(List(Problem), simplifile.FileError) {
  use text <- result.map(simplifile.read(path))
  check.check_release_notes_template(path, text)
}

pub fn release_notes_test() {
  let assert Ok([]) = template_problems("releases/release-1.0.0.md")
}
```

On the release notes of this package, `release_notes_test` passes. On the complete file above without `## Community`, `template_problems` returns `Ok([Problem(<path>, 1, MissingReleaseNotesSection("Community"))])`. The template itself is a constant, `check.release_notes_template`, if a tool of yours needs the list of sections.

## Common pitfalls

**Old release notes with no tag.** *Symptom:* after `gleam.toml` moves to `0.2.0`, the notes of `0.1.0` fail with `this block is in the docs of the release 0.1.0, so it is compared with the files at the tag 0.1.0, but that tag is not in this clone`. *Fix:* run `git fetch --tags`, and use `fetch-depth: 0` in CI. If the release never got its tag, tag its release commit. Don't change the badge links: the notes of `0.1.0` link at `0.1.0`.

**Notes of a release you haven't set in gleam.toml yet.** *Symptom:* `this block is in the docs of the release 0.3.0, which is neither 0.2.0, the version in gleam.toml, nor a release before it`. *Fix:* set `version = "0.3.0"` in `gleam.toml` when you start the notes of `0.3.0`.

**A `#` title with extra words.** *Symptom:* `the template wants the title "# <Name> 0.2.0 Release Notes"`. *Fix:* the title ends with the version and `Release Notes`, nothing after them.

**A section heading with another spelling.** *Symptom:* `"## Whats New" is not a section of the release notes template`. *Fix:* copy the headings from [the list](#the-sections). The text must match exactly, including `What's New` with its apostrophe.

**Notes of a release before your tested docs.** *Symptom:* old notes fail on code blocks that were right for their own version. *Fix:* set `checked_from_version` to the first version with tested docs. Older notes and changelog sections are skipped.

## Where to go next

- [Show an API change in an upgrade guide](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/upgrade-guides.md): old and new code for the `Upgrading` section.
- [Settings and checks reference](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/reference.md): `release_notes`, `checked_from_version` and `release_notes_guide`.
- [Fix a failed check](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/fixing-check-failures.md): every other message.
- [API reference on HexDocs](https://hexdocs.pm/dream_snippets/dream_snippets/check.html#check_release_notes_template): `check_release_notes_template`, `check_release_notes` and `release_notes_template`.
