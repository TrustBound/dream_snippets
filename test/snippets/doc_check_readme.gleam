//// Doc comment: check.check_readme
////
//// Checks a README whose example has no guide badge.

import dream_snippets/check.{
  type Report, CheckContext, GitHubRepository, Project, Version,
}
import dream_snippets/git

pub fn check_my_readme() -> Report {
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
      read_source: fn(_path) { Ok("pub const answer = 42\n") },
      tag_exists: fn(_tag) { Error(git.GitNotFound) },
      diff_from_tag: fn(_tag, _path) { Error(git.GitNotFound) },
      diff_between_tags: fn(_old_tag, _new_tag, _path) {
        Error(git.GitNotFound)
      },
      file_at_tag: fn(_tag, _path) { Error(git.GitNotFound) },
    )
  let heading =
    "### The answer <a href=\"https://github.com/me/my_app/blob/1.2.0/test/snippets/answer.gleam\"><img align=\"right\" alt=\"Tested snippet\" src=\"https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square\"></a>"
  let readme =
    "# My app\n\n" <> heading <> "\n\n```gleam\npub const answer = 42\n```\n"
  // Returns Report(..empty_report(), blocks_checked: 1, problems: [
  //   Problem(file: "README.md", line: 3, reason: MissingGuideBadge),
  // ])
  check.check_readme("README.md", readme, context)
}
