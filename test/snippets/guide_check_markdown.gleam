//// Guide: check one document
////
//// Checks a Markdown document with the pure checks and a fake git.

import dream_snippets/check.{
  type Report, CheckContext, GitHubRepository, Project, Version,
}
import dream_snippets/git
import simplifile

pub fn check_guide(guide: String) -> Report {
  let project =
    Project(
      name: "my_app",
      version: "1.2.0",
      repository: GitHubRepository(owner: "me", name: "my_app"),
      badge_guide: "CONTRIBUTING.md",
      release_notes_guide: "CONTRIBUTING.md",
      guides: ["docs/guides"],
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
  check.check_markdown("docs/guide.md", guide, context)
}
