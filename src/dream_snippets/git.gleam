//// Runs git for the diff blocks: tells whether a release tag is in the
//// local clone, and reads the git diff of one file from a tag to the
//// working tree.
////
//// git starts directly, with no shell between, and its options fix the
//// output format, so the settings of a user cannot change what the check
//// sees. Only `dream_snippets` calls these functions for a real project;
//// the checks in `dream_snippets/check` get them through a `CheckContext`,
//// so tests can give fake ones.

import gleam/int

/// The git program to run, and the directory to run it in.
///
/// `program` is the name of the program, which is looked up on the `PATH`
/// (normally `"git"`). `directory` is the repository root, for example
/// `"."`.
pub type Git {
  Git(program: String, directory: String)
}

/// Why git could not answer.
pub type GitError {
  /// The program is not on the `PATH`.
  GitNotFound
  /// git stopped with an exit status that is not 0. `output` is what it
  /// wrote to standard output.
  GitFailed(status: Int, output: String)
}

/// Tells whether a tag is in the local clone.
///
/// It runs `git rev-parse --verify --quiet refs/tags/<tag>^{commit}`. git
/// exits with status 1 and no output when the tag is missing.
///
/// ## Parameters
///
/// - `git`: the program and the repository directory
/// - `tag`: the tag name. It must pass `check.is_safe_tag`.
///
/// ## Returns
///
/// `Ok(True)` when the tag names a commit, `Ok(False)` when it does not.
///
/// ## Errors
///
/// `GitNotFound` when the program is not on the `PATH`, and `GitFailed` for
/// any other failure of git, for example a directory that is not a git
/// repository.
pub fn tag_exists(git: Git, tag: String) -> Result(Bool, GitError) {
  let arguments = [
    "rev-parse",
    "--verify",
    "--quiet",
    "refs/tags/" <> tag <> "^{commit}",
  ]
  case run(git, arguments) {
    Ok(_commit) -> Ok(True)
    Error(GitFailed(status: 1, output: "")) -> Ok(False)
    Error(error) -> Error(error)
  }
}

/// Returns the text of `git diff` for one path, from a tag to the working
/// tree.
///
/// The options fix the output format, so that the git settings of a user
/// (colours, prefixes, external diff tools, the diff algorithm, the number
/// of context lines) cannot change it. The path comes after `--`, so git
/// never reads it as an option.
///
/// ## Parameters
///
/// - `git`: the program and the repository directory
/// - `tag`: the old tag. It must pass `check.is_safe_tag`.
/// - `path`: the file, relative to the repository root. It must pass
///   `check.is_safe_path`.
///
/// ## Returns
///
/// The diff text, or an empty string when the file did not change.
///
/// ## Errors
///
/// `GitNotFound` or `GitFailed`, as for `tag_exists`.
pub fn diff_from_tag(
  git: Git,
  tag: String,
  path: String,
) -> Result(String, GitError) {
  run(git, [
    "-c",
    "core.quotepath=off",
    "diff",
    "--no-color",
    "--no-ext-diff",
    "--no-textconv",
    "--no-renames",
    "--src-prefix=a/",
    "--dst-prefix=b/",
    "--unified=3",
    "--diff-algorithm=myers",
    "--indent-heuristic",
    "refs/tags/" <> tag,
    "--",
    path,
  ])
}

/// Runs git with the arguments in the directory of `git`, with no shell
/// between, and returns its standard output. Standard error is not
/// captured: git prints it to the terminal.
///
/// ## Errors
///
/// `GitNotFound` when the program is not on the `PATH`, and
/// `GitFailed(status, output)` when it exits with a status that is not 0.
pub fn run(git: Git, arguments: List(String)) -> Result(String, GitError) {
  run_program(git.program, git.directory, arguments)
}

@external(erlang, "dream_snippets_ffi", "run_program")
fn run_program(
  program: String,
  directory: String,
  arguments: List(String),
) -> Result(String, GitError)

/// Describes why git could not answer, in a few words, for example
/// `git stopped with exit status 128`.
pub fn describe_error(error: GitError) -> String {
  case error {
    GitNotFound -> "git is not on the PATH"
    GitFailed(status:, output: _) ->
      "git stopped with exit status " <> int.to_string(status)
  }
}
