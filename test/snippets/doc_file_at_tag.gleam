//// Doc comment: git.file_at_tag
////
//// Reads src/app.gleam as it was at the tag 1.0.0.

import dream_snippets/git.{type GitError, Git}
import gleam/option.{type Option}

pub fn app_at_first_release(
  directory: String,
) -> Result(Option(String), GitError) {
  // Returns Ok(Some(text)) when src/app.gleam is a file at the tag 1.0.0,
  // and Ok(None) when it is not
  git.file_at_tag(Git(program: "git", directory:), "1.0.0", "src/app.gleam")
}
