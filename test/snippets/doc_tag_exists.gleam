//// Doc comment: git.tag_exists
////
//// Tells whether the tag 1.0.0 is in a repository.

import dream_snippets/git.{type GitError, Git}

pub fn has_first_release(directory: String) -> Result(Bool, GitError) {
  // Returns Ok(True) in a repository with the tag 1.0.0
  git.tag_exists(Git(program: "git", directory:), "1.0.0")
}
