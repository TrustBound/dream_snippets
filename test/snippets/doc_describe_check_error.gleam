//// Doc comment: dream_snippets.describe_error
////
//// Describes an error that stops the check.

import dream_snippets.{MissingRoot}

pub fn missing_root_message() -> String {
  // Returns "examples is set in [tools.dream_snippets] in gleam.toml, but it does not exist"
  dream_snippets.describe_error(MissingRoot("examples"))
}
