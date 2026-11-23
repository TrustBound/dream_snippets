# Changelog

All notable changes to `dream_snippets` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - Unreleased

### Added

- `gleam run -m dream_snippets` checks that each code block in the docs of
  a Gleam project matches a tested snippet file. It is the snippet check of
  the Dream repository, moved to its own package, with the same checks and
  the same messages.
- The repository that badges link at comes from the `repository` field of
  `gleam.toml`, and the release tag from its `version`.
- An optional `[tools.dream_snippets]` table in `gleam.toml` sets the
  checked places (`markdown`, `changelog`, `release_notes`,
  `gleam_source`), `checked_from_version`, `guides`, `badge_guide` and
  `release_notes_guide`.
- By default every changelog section and every release note is checked
  (`checked_from_version = "0.0.0"`). A project sets
  `checked_from_version` to start the check at a later version.
- By default a malformed badge message tells the reader to copy the badge
  from https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html,
  the guide that shows the exact headings and badges. A project sets
  `badge_guide` to point at its own page.
- Each checked release notes file must follow the release notes template:
  the title `# <Name> <version> Release Notes`, a `**Release Date:**`
  line, and only the template's `##` sections, in its order, with each
  required one. `## Upgrading` must have a `### Migration Guide`. The
  template is in one place, `check.release_notes_template`, and
  `check.check_release_notes_template` checks one file. A template
  message points at
  https://hexdocs.pm/dream_snippets/guides/release-notes-template.html,
  and a project sets `release_notes_guide` to point at its own page.
- Each example heading in the root `README.md` has a guide badge after its
  tested snippet badge. The guide badge links to the section of a guide
  that shows the example, at the release tag. The check makes sure that
  the guide is a `.md` file under a guide directory, that the anchor is a
  heading of the guide, and that the guide links to the same snippet file.
  A heading outside the README must not have a guide badge.
  `check.check_readme` checks a README, and `check.heading_anchors` gives
  the GitHub anchors of the headings of a document.
- The `guides` setting lists the guide directories. The default is
  `["docs/guides"]`.
- The docs of this package are in guides under `docs/guides`, and HexDocs
  shows each guide as a page. The README lists them.
