//// Doc comment: git.run
////
//// Runs git and returns its standard output.

import dream_snippets/git.{type GitError, Git}

pub fn list_tags(directory: String) -> Result(String, GitError) {
  // Returns Ok("1.0.0\n") in a repository with the one tag 1.0.0
  git.run(Git(program: "git", directory:), ["tag", "--list"])
}
