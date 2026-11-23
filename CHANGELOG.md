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
  `gleam_source`), `checked_from_version` and `badge_guide`.
- By default every changelog section and every release note is checked
  (`checked_from_version = "0.0.0"`). A project sets
  `checked_from_version` to start the check at a later version.
- By default a malformed badge message tells the reader to copy the badge
  from https://hexdocs.pm/dream_snippets, where the README shows the exact
  heading and badge. A project sets `badge_guide` to point at its own page.
