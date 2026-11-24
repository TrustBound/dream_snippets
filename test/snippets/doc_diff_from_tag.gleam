//// Doc comment: git.diff_from_tag
////
//// Reads the diff of one file from the tag 1.0.0 to the working tree.

import dream_snippets/git.{type GitError, Git}

pub fn changes_since_first_release(
  directory: String,
) -> Result(String, GitError) {
  // Returns Ok("") when src/app.gleam did not change after the tag 1.0.0
  git.diff_from_tag(Git(program: "git", directory:), "1.0.0", "src/app.gleam")
}
