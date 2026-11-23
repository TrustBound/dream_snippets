//// Guide: Release notes template, test your code
////
//// A test that fails when release notes do not follow the template.

import dream_snippets/check.{type Problem}
import gleam/result
import simplifile

/// The template problems of one release notes file.
pub fn template_problems(
  path: String,
) -> Result(List(Problem), simplifile.FileError) {
  use text <- result.map(simplifile.read(path))
  check.check_release_notes_template(path, text)
}

pub fn release_notes_test() {
  let assert Ok([]) = template_problems("releases/release-1.0.0.md")
}
