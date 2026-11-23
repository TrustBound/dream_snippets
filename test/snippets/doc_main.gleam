//// Doc comment: dream_snippets.main
////
//// A module that runs the check of the docs, as `gleam run -m dream_snippets` does.

import dream_snippets

pub fn main() -> Nil {
  // Prints each problem and the summary line, and stops with exit status 1
  // when there is a problem.
  dream_snippets.main()
}
