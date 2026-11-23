//// Doc comment: check.describe_reason
////
//// Describes why a code block fails the check.

import dream_snippets/check.{GitHubRepository, Project, WrongTag}

pub fn wrong_tag_reason() -> String {
  let project =
    Project(
      name: "my_app",
      version: "1.2.0",
      repository: GitHubRepository(owner: "me", name: "my_app"),
      badge_guide: "CONTRIBUTING.md",
      release_notes_guide: "CONTRIBUTING.md",
      guides: ["docs/guides"],
    )
  // Returns "the badge link uses the tag 1.1.0, but this file must link at the
  // tag 1.2.0 (the docs of my_app use the version in gleam.toml)"
  check.describe_reason(WrongTag(found: "1.1.0", expected: "1.2.0"), project)
}
