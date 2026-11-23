# Changelog

All notable changes to `dream_snippets` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - Unreleased

### Added

- `gleam run -m dream_snippets` checks that each code block in the docs of
  a Gleam project matches a tested snippet file. It is the snippet check of
  the Dream repository, moved to its own package, with the same checks.
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
- A `release_notes` path can be one file. It follows the rules of a file
  in a directory: it is skipped when its version is before
  `checked_from_version`, and a name that is not `release-<version>.md`
  gets one problem at line 1 of the file.
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
- A guide or release notes can show code at an older release. The heading
  ends with a "code at an older release" badge that links to a file at an
  older release tag, with an optional line range. The check makes sure
  that the tag is a release before the `version` in `gleam.toml` and is
  in the clone, that the path is a file at that tag, and that the block
  is the same as those lines, byte for byte. It reads the file with
  `git show <tag>:<path>`. The badge is a problem in the README, the
  changelog and doc comments. `check.parse_old_code_heading` reads the
  badge, `check.check_release_notes` checks release notes, and
  `git.file_at_tag` reads a file at a tag.
- A git failure message now starts with "cannot run git", because git
  also reads files at a tag.
- Release notes and changelog sections belong to their own release. The
  release of `releases/release-<version>.md` and of a `## [<version>]`
  changelog section is that version. Their badge links and the new tag of
  their diffs use its tag. While it is the `version` in `gleam.toml`, the
  blocks are compared with the working tree. Once it is an older release,
  they are compared with the files at its tag, and a diff is
  `git diff <old tag> <tag> -- <path>`. So the docs of a release stay
  right after each version bump, with no change. Every other document,
  the `## [Unreleased]` section and the text before the first section
  belong to the `version` in `gleam.toml`. A missing tag of an older
  release, and a release after the `version` in `gleam.toml`, are
  problems. `git.diff_between_tags` reads the diff between two tags.
- Versions follow the order of semver 2.0.0: a pre-release comes before
  its release, and pre-release identifiers compare from left to right.
  So code at `2.0.0-rc.1` is code at an older release for `2.0.0`.
  `check.compare_versions` is the one place that orders versions, and
  `check.Version` holds the pre-release identifiers.
- Each problem and each error is exactly one line. A control character in
  a file name, a value or a message shows as `\n`, `\r`, `\t` or
  `\u{<hex>}`. `check.one_line` does it for every message.
- The summary line uses the singular for a count of 1, as in
  `1 block and 0 diff blocks checked in 1 file, 1 problem`.
- The docs of this package are seven pages under `docs/guides`, and
  HexDocs shows each one as a page. The README lists them. Six are guides
  that each walk through one task from start to finish: "Getting
  started", "Tested code blocks", "Fix a failed check", "Show an API
  change in an upgrade guide", "Release notes template" and "Use it from
  Gleam". "Settings and checks reference" lists every setting with its
  default and every check. Each output that a guide shows is asserted by
  a test.
- Every public function has a tested example in its doc comment: 47
  functions, each with a snippet file under `test/snippets/`. Each public
  function is named in a guide where a reader needs it.
