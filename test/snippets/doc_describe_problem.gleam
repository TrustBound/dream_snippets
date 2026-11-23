//// Doc comment: check.describe_problem
////
//// Describes a problem in one line.

import dream_snippets/check.{GitHubRepository, Problem, Project, UnclosedFence}

pub fn problem_line() -> String {
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
  // Returns "README.md:14: this code fence has no closing fence"
  check.describe_problem(Problem("README.md", 14, UnclosedFence), project)
}
