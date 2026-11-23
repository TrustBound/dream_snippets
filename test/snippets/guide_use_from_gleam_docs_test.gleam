//// Guide: Use it from Gleam, step 2
////
//// A test that fails when the docs check finds a problem.

import dream_snippets

pub fn docs_test() {
  let output = dream_snippets.output(dream_snippets.check_project("."))
  let assert [_summary] = output.standard_output
}
