//// Doc comment: config.describe_error
////
//// Describes why gleam.toml cannot be used.

import dream_snippets/config.{NameNotFound}

pub fn name_not_found_message() -> String {
  // Returns "gleam.toml has no name = \"...\" line before its first [section]"
  config.describe_error(NameNotFound)
}
