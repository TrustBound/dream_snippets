//// Doc comment: git.diff_between_tags
////
//// Reads the diff of one file from the tag 1.0.0 to the tag 1.1.0.

import dream_snippets/git.{type GitError, Git}

pub fn changes_in_second_release(
  directory: String,
) -> Result(String, GitError) {
  let repository = Git(program: "git", directory:)
  // Returns Ok("") when src/app.gleam is the same at the tags 1.0.0 and 1.1.0
  git.diff_between_tags(repository, "1.0.0", "1.1.0", "src/app.gleam")
}
