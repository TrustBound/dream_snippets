//// Doc comment: dream_snippets.output
////
//// Turns the result of a check into what the command prints.

import dream_snippets.{type Output, MissingRoot}

pub fn output_of_missing_root() -> Output {
  // Returns Output(
  //   standard_output: [],
  //   standard_error: [
  //     "error: docs is set in [tools.dream_snippets] in gleam.toml, but it does not exist",
  //   ],
  //   exit_status: 1,
  // )
  dream_snippets.output(Error(MissingRoot("docs")))
}
