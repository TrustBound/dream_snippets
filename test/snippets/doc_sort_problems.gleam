//// Doc comment: check.sort_problems
////
//// Sorts problems by file, then by line.

import dream_snippets/check.{
  type Problem, MissingBadgeHeading, MissingReleaseDate, Problem, UnclosedFence,
}

pub fn sorted_problems() -> List(Problem) {
  // Returns [
  //   Problem("CHANGELOG.md", 4, UnclosedFence),
  //   Problem("README.md", 2, MissingReleaseDate),
  //   Problem("README.md", 9, MissingBadgeHeading),
  // ]
  check.sort_problems([
    Problem("README.md", 9, MissingBadgeHeading),
    Problem("CHANGELOG.md", 4, UnclosedFence),
    Problem("README.md", 2, MissingReleaseDate),
  ])
}
