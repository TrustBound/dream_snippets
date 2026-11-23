//// Doc comment: check.check_changelog
////
//// Checks a changelog, and leaves out the sections before version 1.0.0.

import dream_snippets/check.{
  type Report, CheckContext, GitHubRepository, Project, Version,
}
import dream_snippets/git
import simplifile

pub fn check_my_changelog() -> Report {
  let project =
    Project(
      name: "my_app",
      version: "1.2.0",
      repository: GitHubRepository(owner: "me", name: "my_app"),
      badge_guide: "CONTRIBUTING.md",
      release_notes_guide: "CONTRIBUTING.md",
      guides: ["docs/guides"],
      tested_files: ["test", ".github"],
      dependencies: [],
    )
  let context =
    CheckContext(
      project:,
      checked_from_version: Version(1, 0, 0, []),
      read_source: simplifile.read,
      tag_exists: fn(_tag) { Error(git.GitNotFound) },
      diff_from_tag: fn(_tag, _path) { Error(git.GitNotFound) },
      diff_between_tags: fn(_old_tag, _new_tag, _path) {
        Error(git.GitNotFound)
      },
      file_at_tag: fn(_tag, _path) { Error(git.GitNotFound) },
    )
  let changelog =
    "# Changelog\n\n## [Unreleased]\n\n```gleam\nnew_code()\n```\n\n"
    <> "## [0.9.0] - 2026-01-10\n\n```gleam\nold_code()\n```\n"
  // Returns Report(..empty_report(), blocks_checked: 1, problems: [
  //   Problem(file: "CHANGELOG.md", line: 5, reason: MissingBadgeHeading),
  // ])
  check.check_changelog("CHANGELOG.md", changelog, context)
}
