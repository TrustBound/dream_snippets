//// Doc comment: dream_snippets.check_project
////
//// Checks the project in a directory and returns what the command prints.

import dream_snippets

pub fn summary_of(directory: String) -> List(String) {
  let output = dream_snippets.output(dream_snippets.check_project(directory))
  output.standard_output
}
