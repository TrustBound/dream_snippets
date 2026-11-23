//// Guide: Use it from Gleam, step 3
////
//// Prints each problem as a GitHub Actions annotation.

import dream_snippets.{type CheckError}
import dream_snippets/check.{type Problem, type Project}
import gleam/int
import gleam/list
import gleam/result

/// One `::error` line for each problem of the project in `directory`,
/// sorted by file and line. GitHub shows each one on the line it names.
pub fn annotations(directory: String) -> Result(List(String), CheckError) {
  use checked <- result.map(dream_snippets.check_project(directory))
  checked.report.problems
  |> check.sort_problems
  |> list.map(fn(problem) { annotation(problem, checked.project) })
}

fn annotation(problem: Problem, project: Project) -> String {
  "::error file="
  <> problem.file
  <> ",line="
  <> int.to_string(problem.line)
  <> "::"
  <> check.describe_reason(problem.reason, project)
}
