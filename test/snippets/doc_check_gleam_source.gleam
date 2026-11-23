//// Doc comment: check.check_gleam_source
////
//// Checks the code blocks in the doc comments of a Gleam source file.

import dream_snippets/check.{
  type Report, CheckContext, GitHubRepository, Project, Version,
}
import dream_snippets/git
import simplifile

pub fn check_my_source() -> Report {
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
  let source =
    "/// Says hello.
///
/// ```gleam
/// hello()
/// ```
pub fn hello() -> Nil {
  Nil
}
"
  // Returns Report(..empty_report(), blocks_checked: 1, problems: [
  //   Problem(file: "src/app.gleam", line: 3, reason: MissingBadgeHeading),
  // ])
  check.check_gleam_source("src/app.gleam", source, context)
}
