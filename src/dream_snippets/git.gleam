//// Runs git for the diff blocks and the blocks of code at an older
//// release: tells whether a release tag is in the local clone, reads the
//// git diff of one file from a tag to the working tree or to another tag,
//// and reads a file as it was at a tag.
////
//// git starts directly, with no shell between, and its options fix the
//// output format, so the settings of a user cannot change what the check
//// sees. Only `dream_snippets` calls these functions for a real project;
//// the checks in `dream_snippets/check` get them through a `CheckContext`,
//// so tests can give fake ones.

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

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
/// ## Examples
///
/// ### Find a release tag <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/doc_tag_exists.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_snippets/git.{type GitError, Git}
///
/// pub fn has_first_release(directory: String) -> Result(Bool, GitError) {
///   // Returns Ok(True) in a repository with the tag 1.0.0
///   git.tag_exists(Git(program: "git", directory:), "1.0.0")
/// }
/// ```
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
/// ## Examples
///
/// ### Read the diff of a file from a tag <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/doc_diff_from_tag.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_snippets/git.{type GitError, Git}
///
/// pub fn changes_since_first_release(
///   directory: String,
/// ) -> Result(String, GitError) {
///   // Returns Ok("") when src/app.gleam did not change after the tag 1.0.0
///   git.diff_from_tag(Git(program: "git", directory:), "1.0.0", "src/app.gleam")
/// }
/// ```
///
/// ## Errors
///
/// `GitNotFound` or `GitFailed`, as for `tag_exists`.
pub fn diff_from_tag(
  git: Git,
  tag: String,
  path: String,
) -> Result(String, GitError) {
  run(git, diff_arguments(["refs/tags/" <> tag], path))
}

/// Returns the text of `git diff` for one path, from an old tag to a new
/// tag. It is the diff of a diff block in the release notes or changelog
/// section of an older release, whose new side is the tag of that release.
///
/// It uses the same fixed options as `diff_from_tag`.
///
/// ## Parameters
///
/// - `git`: the program and the repository directory
/// - `old_tag` and `new_tag`: the two tags. Each must pass
///   `check.is_safe_tag`.
/// - `path`: the file, relative to the repository root. It must pass
///   `check.is_safe_path`.
///
/// ## Returns
///
/// The diff text, or an empty string when the file is the same at both
/// tags.
///
/// ## Examples
///
/// ### Read the diff of a file between two tags <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/doc_diff_between_tags.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_snippets/git.{type GitError, Git}
///
/// pub fn changes_in_second_release(
///   directory: String,
/// ) -> Result(String, GitError) {
///   let repository = Git(program: "git", directory:)
///   // Returns Ok("") when src/app.gleam is the same at the tags 1.0.0 and 1.1.0
///   git.diff_between_tags(repository, "1.0.0", "1.1.0", "src/app.gleam")
/// }
/// ```
///
/// ## Errors
///
/// `GitNotFound` or `GitFailed`, as for `tag_exists`.
pub fn diff_between_tags(
  git: Git,
  old_tag: String,
  new_tag: String,
  path: String,
) -> Result(String, GitError) {
  run(
    git,
    diff_arguments(["refs/tags/" <> old_tag, "refs/tags/" <> new_tag], path),
  )
}

/// The arguments of `git diff` with the fixed output format, for the
/// revisions and one path.
fn diff_arguments(revisions: List(String), path: String) -> List(String) {
  list.flatten([
    [
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
    ],
    revisions,
    ["--", path],
  ])
}

/// Returns the text of a file as it was at a tag.
///
/// It runs `git ls-tree --full-tree refs/tags/<tag> -- <path>` to find
/// out whether the path is a file at the tag. When it is, it runs
/// `git show --no-textconv refs/tags/<tag>:<path>` and returns the output.
/// The path comes after `--` or after the `:`, so git never reads it as an
/// option.
///
/// ## Parameters
///
/// - `git`: the program and the repository directory
/// - `tag`: the tag. It must pass `check.is_safe_tag`.
/// - `path`: the file, relative to the repository root. It must pass
///   `check.is_safe_path`.
///
/// ## Returns
///
/// `Ok(Some(text))` when the path is a file at the tag, and `Ok(None)`
/// when the tag has no file at that path (no entry, or a directory).
///
/// ## Examples
///
/// ### Read a file at a tag <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/doc_file_at_tag.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_snippets/git.{type GitError, Git}
/// import gleam/option.{type Option}
///
/// pub fn app_at_first_release(
///   directory: String,
/// ) -> Result(Option(String), GitError) {
///   // Returns Ok(Some(text)) when src/app.gleam is a file at the tag 1.0.0,
///   // and Ok(None) when it is not
///   git.file_at_tag(Git(program: "git", directory:), "1.0.0", "src/app.gleam")
/// }
/// ```
///
/// ## Errors
///
/// `GitNotFound` or `GitFailed`, as for `tag_exists`. A tag that is not in
/// the clone is a `GitFailed`, so check it with `tag_exists` first.
pub fn file_at_tag(
  git: Git,
  tag: String,
  path: String,
) -> Result(Option(String), GitError) {
  let reference = "refs/tags/" <> tag
  use entry <- result.try(
    run(git, ["ls-tree", "--full-tree", reference, "--", path]),
  )
  show_if_file(git, reference, path, entry)
}

/// Shows the file when the `ls-tree` entry names a file (a blob) at
/// exactly that path.
fn show_if_file(
  git: Git,
  reference: String,
  path: String,
  entry: String,
) -> Result(Option(String), GitError) {
  case is_file_entry(entry, path) {
    True ->
      run(git, ["show", "--no-textconv", reference <> ":" <> path])
      |> result.map(Some)
    False -> Ok(None)
  }
}

/// An `ls-tree` entry is `<mode> <type> <object>\t<path>` and a newline.
fn is_file_entry(entry: String, path: String) -> Bool {
  case string.split_once(entry, "\t") {
    Ok(#(description, entry_path)) ->
      string.contains(description, " blob ") && entry_path == path <> "\n"
    Error(Nil) -> False
  }
}

/// Runs git with the arguments in the directory of `git`, with no shell
/// between, and returns its standard output. Standard error is not
/// captured: git prints it to the terminal.
///
/// ## Examples
///
/// ### Run git <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/doc_run_git.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_snippets/git.{type GitError, Git}
///
/// pub fn list_tags(directory: String) -> Result(String, GitError) {
///   // Returns Ok("1.0.0\n") in a repository with the one tag 1.0.0
///   git.run(Git(program: "git", directory:), ["tag", "--list"])
/// }
/// ```
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
///
/// ## Examples
///
/// ### Describe why git failed <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/doc_describe_git_error.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_snippets/git.{GitFailed}
///
/// pub fn git_failure_message() -> String {
///   // Returns "git stopped with exit status 128"
///   git.describe_error(GitFailed(status: 128, output: ""))
/// }
/// ```
pub fn describe_error(error: GitError) -> String {
  case error {
    GitNotFound -> "git is not on the PATH"
    GitFailed(status:, output: _) ->
      "git stopped with exit status " <> int.to_string(status)
  }
}
