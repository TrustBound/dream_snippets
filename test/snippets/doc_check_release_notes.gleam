//// Doc comment: check.check_release_notes
////
//// Checks release notes that show code at an older release.

import dream_snippets/check.{
  type Report, CheckContext, GitHubRepository, Project, Version,
}
import gleam/option.{Some}

pub fn check_my_release_notes() -> Report {
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
      read_source: fn(_path) { Ok("") },
      tag_exists: fn(tag) { Ok(tag == "1.1.0") },
      diff_from_tag: fn(_tag, _path) { Ok("") },
      diff_between_tags: fn(_old_tag, _new_tag, _path) { Ok("") },
      file_at_tag: fn(_tag, _path) { Ok(Some("pub const answer = 41\n")) },
    )
  let heading =
    "### The answer in 1.1 <a href=\"https://github.com/me/my_app/blob/1.1.0/src/app.gleam\"><img align=\"right\" alt=\"Code at 1.1.0\" src=\"https://img.shields.io/badge/%F0%9F%93%9C_code_at-1.1.0-lightgrey.svg?style=flat-square\"></a>"
  let notes =
    "# my_app 1.2.0 Release Notes\n\n**Release Date:** 2026-11-20\n\n"
    <> heading
    <> "\n\n```gleam\npub const answer = 41\n```\n"
  // The old code block passes. The notes have no sections, so it returns
  // Report(blocks_checked: 1, diff_blocks_checked: 0, problems: [
  //   Problem(file, 1, MissingReleaseNotesSection("Key Highlights")),
  //   Problem(file, 1, MissingReleaseNotesSection("What's New")),
  //   Problem(file, 1, MissingReleaseNotesSection("Testing")),
  //   Problem(file, 1, MissingReleaseNotesChoice(["Upgrading", "Installing"])),
  //   Problem(file, 1, MissingReleaseNotesSection("Documentation")),
  //   Problem(file, 1, MissingReleaseNotesSection("Community")),
  // ])
  // where file is "releases/release-1.2.0.md"
  check.check_release_notes("releases/release-1.2.0.md", notes, context)
}
