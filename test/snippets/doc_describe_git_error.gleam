//// Doc comment: git.describe_error
////
//// Describes why git could not answer.

import dream_snippets/git.{GitFailed}

pub fn git_failure_message() -> String {
  // Returns "git stopped with exit status 128"
  git.describe_error(GitFailed(status: 128, output: ""))
}
