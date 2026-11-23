# Configuration

This guide shows the settings of the check. The check needs no settings, and an optional table in `gleam.toml` changes the defaults.

## What the check reads from gleam.toml

The check reads `name`, `version` and `repository` from `gleam.toml`. The repository must be on GitHub. Each badge links to that repository, at the tag of the `version`.

## The settings and their defaults

An optional `[tools.dream_snippets]` table changes the defaults. These are the defaults:

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
# Directories of guides: the guide badge of a README example links to a
# .md file under one of them
guides = ["docs/guides"]
# Where the message for a malformed badge tells the reader to copy it from
badge_guide = "https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html"
# Where a release notes template message tells the reader to read the
# "Release notes template" guide
release_notes_guide = "https://hexdocs.pm/dream_snippets/guides/release-notes-template.html"
```

By default the check examines every changelog section and every release note. A message about a malformed badge points at the [Tested code blocks](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md) guide on HexDocs:

```text
README.md:12: the tested snippet badge is not in the exact format; copy it from https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html
```

## Change the defaults

Release notes and changelog sections from before the project had tested docs show code that was right for their own version. Set `checked_from_version` to the first version with tested docs, so the check starts there.

Set `badge_guide` to a page of your own that shows the badges, for example a contributing guide. Set `release_notes_guide` to a page of your own with a "Release notes template" section. Set `guides` when your guides are in another directory.

A project with tested docs from 1.1.0 and its own guide sets two settings:

```toml
[tools.dream_snippets]
checked_from_version = "1.1.0"
badge_guide = "docs/contributing.md"
```

## Rules for the lists

A list that you set replaces the default list of its kind. Each path of a `markdown`, `changelog`, `release_notes` or `gleam_source` list that you set must exist. The check skips a default path that does not exist. The check never walks the directories `build`, `deps`, `_build` and `node_modules`. Any other key in the table is an error.

The `guides` directories are not walked. They only tell where a guide badge can link. Add them to `markdown` too, so the check examines the code blocks of the guides. The default `docs` root holds `docs/guides`.
