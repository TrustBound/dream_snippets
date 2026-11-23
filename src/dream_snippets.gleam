//// Checks that every code block in the docs of a Gleam project matches a
//// tested snippet file.
////
//// Run it from the project root:
////
//// ```bash
//// gleam run -m dream_snippets
//// ```
////
//// It prints one line for each problem, as `file:line: reason`, sorted by
//// file and line, then a summary line, for example
//// `12 blocks and 0 diff blocks checked in 9 files, 0 problems`. It stops
//// with exit code 1 when it finds a problem or cannot run. It never uses the
//// network: a badge link is changed to a local path and the file is read
//// from the working tree. For a `diff` block it runs `git diff` in the
//// project root, and for code at an older release it runs `git ls-tree`
//// and `git show` there.
////
//// The rules are in `dream_snippets/check`. The settings, read from the
//// `gleam.toml` of the project, are in `dream_snippets/config`.

import dream_snippets/check.{type Project, type Report, type Version, Report}
import dream_snippets/config.{
  type CheckedRoot, type ConfigError, MayBeMissing, MustExist,
}
import dream_snippets/git.{Git}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

/// Directory names that are never walked inside a checked root. They hold
/// build output and downloaded dependencies (for example
/// `examples/tasks/deps/` and `examples/simple/build/packages/`), whose
/// docs belong to other projects.
const skipped_directory_names = ["build", "deps", "_build", "node_modules"]

/// The path of the root README, relative to the project root. Its example
/// headings carry the guide badge.
const readme_path = "README.md"

/// An error that stops the check before it can report.
pub type CheckError {
  /// `gleam.toml` cannot be used.
  InvalidConfig(error: ConfigError)
  /// A path could not be looked at, or a directory could not be listed.
  ListFailed(path: String, reason: simplifile.FileError)
  /// A document could not be read.
  ReadFailed(path: String, reason: simplifile.FileError)
  /// A root that `[tools.dream_snippets]` sets does not exist.
  MissingRoot(path: String)
}

/// The result of checking a project: the project, the report of all its
/// documents, and the number of files that were checked.
pub type ProjectReport {
  ProjectReport(project: Project, report: Report, file_count: Int)
}

/// What the command prints, and the status it stops with.
pub type Output {
  Output(
    standard_output: List(String),
    standard_error: List(String),
    exit_status: Int,
  )
}

/// Checks the docs of the project in the current directory, prints each
/// problem and a summary, and stops with exit code 1 if there is a problem
/// or an error, so that `make` targets, hooks and CI fail too.
///
/// ## Examples
///
/// ### Run the check from a module of your project <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/doc_main.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_snippets
///
/// pub fn main() -> Nil {
///   // Prints each problem and the summary line, and stops with exit status 1
///   // when there is a problem.
///   dream_snippets.main()
/// }
/// ```
pub fn main() -> Nil {
  let result = output(check_project("."))
  list.each(result.standard_output, io.println)
  list.each(result.standard_error, io.println_error)
  exit(result.exit_status)
}

fn exit(status: Int) -> Nil {
  case status {
    0 -> Nil
    // coverage:ignore halting stops the test run, so no test can run it
    _ -> halt(status)
  }
}

@external(erlang, "erlang", "halt")
fn halt(status: Int) -> Nil

/// Checks every document of a project.
///
/// It reads the configuration from `gleam.toml` (see `config.parse`),
/// lists the files of the checked roots, and checks each one. Snippet files
/// are read from the working tree, and git runs in `directory` for the
/// diff blocks.
///
/// ## Parameters
///
/// - `directory`: the project root, for example `"."`
///
/// ## Returns
///
/// The project, the merged report, and the number of files checked. The
/// paths in the problems are relative to `directory`.
///
/// ## Examples
///
/// ### Check a project and print its summary <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/doc_check_project.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_snippets
///
/// pub fn summary_of(directory: String) -> List(String) {
///   let output = dream_snippets.output(dream_snippets.check_project(directory))
///   output.standard_output
/// }
/// ```
///
/// ## Errors
///
/// `InvalidConfig` when `gleam.toml` cannot be used, `MissingRoot` when a
/// configured root does not exist, and `ListFailed` or `ReadFailed` when a
/// path cannot be listed or read.
pub fn check_project(directory: String) -> Result(ProjectReport, CheckError) {
  use gleam_toml <- result.try(read_document(directory, config.gleam_toml_path))
  use configuration <- result.try(
    config.parse(gleam_toml) |> result.map_error(InvalidConfig),
  )
  use files <- result.try(list_checked_files(directory, configuration))
  let repository = Git(program: "git", directory:)
  let context =
    check.CheckContext(
      project: configuration.project,
      checked_from_version: configuration.checked_from_version,
      read_source: fn(path) { simplifile.read(join(directory, path)) },
      tag_exists: fn(tag) { git.tag_exists(repository, tag) },
      diff_from_tag: fn(tag, path) { git.diff_from_tag(repository, tag, path) },
      diff_between_tags: fn(old_tag, new_tag, path) {
        git.diff_between_tags(repository, old_tag, new_tag, path)
      },
      file_at_tag: fn(tag, path) { git.file_at_tag(repository, tag, path) },
    )
  use reports <- result.try(
    list.try_map(files, fn(file) { check_file(directory, file, context) }),
  )
  Ok(ProjectReport(
    project: configuration.project,
    report: list.fold(reports, empty_report(), add_report),
    file_count: list.length(files),
  ))
}

/// Turns the result of `check_project` into what the command prints and
/// its exit status.
///
/// For a report, the standard output is one line for each problem (see
/// `check.describe_problem`), sorted by file and line, then the summary
/// line (see `check.summary`). The exit status is 0 with no problems and 1
/// otherwise. For an error, the standard error is one line,
/// `error: <description>`, and the exit status is 1.
///
/// ## Examples
///
/// ### Turn an error into the command output <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/doc_output.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_snippets.{type Output, MissingRoot}
///
/// pub fn output_of_missing_root() -> Output {
///   // Returns Output(
///   //   standard_output: [],
///   //   standard_error: [
///   //     "error: docs is set in [tools.dream_snippets] in gleam.toml, but it does not exist",
///   //   ],
///   //   exit_status: 1,
///   // )
///   dream_snippets.output(Error(MissingRoot("docs")))
/// }
/// ```
pub fn output(result: Result(ProjectReport, CheckError)) -> Output {
  case result {
    Ok(project_report) -> report_output(project_report)
    Error(error) ->
      Output(
        standard_output: [],
        standard_error: ["error: " <> describe_error(error)],
        exit_status: 1,
      )
  }
}

fn report_output(project_report: ProjectReport) -> Output {
  let ProjectReport(project:, report:, file_count:) = project_report
  let problems = check.sort_problems(report.problems)
  let problem_lines =
    list.map(problems, fn(problem) { check.describe_problem(problem, project) })
  let summary =
    check.summary(
      report.blocks_checked,
      report.diff_blocks_checked,
      file_count,
      list.length(problems),
    )
  Output(
    standard_output: list.append(problem_lines, [summary]),
    standard_error: [],
    exit_status: int.min(list.length(problems), 1),
  )
}

/// Describes an error that stops the check, in one line (see
/// `check.one_line`).
///
/// ## Examples
///
/// ### Describe an error that stops the check <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/doc_describe_check_error.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_snippets.{MissingRoot}
///
/// pub fn missing_root_message() -> String {
///   // Returns "examples is set in [tools.dream_snippets] in gleam.toml, but it does not exist"
///   dream_snippets.describe_error(MissingRoot("examples"))
/// }
/// ```
pub fn describe_error(error: CheckError) -> String {
  check.one_line(error_text(error))
}

fn error_text(error: CheckError) -> String {
  case error {
    InvalidConfig(error:) -> config.describe_error(error)
    ListFailed(path:, reason:) ->
      "Cannot list " <> path <> ": " <> simplifile.describe_error(reason)
    ReadFailed(path:, reason:) ->
      "Cannot read " <> path <> ": " <> simplifile.describe_error(reason)
    MissingRoot(path:) ->
      path
      <> " is set in [tools.dream_snippets] in gleam.toml, but it does not exist"
  }
}

fn join(directory: String, path: String) -> String {
  directory <> "/" <> path
}

fn read_document(
  directory: String,
  path: String,
) -> Result(String, CheckError) {
  simplifile.read(join(directory, path))
  |> result.map_error(ReadFailed(path, _))
}

fn check_file(
  directory: String,
  file: #(String, check.DocumentKind),
  context: check.CheckContext,
) -> Result(Report, CheckError) {
  let #(path, kind) = file
  use text <- result.map(read_document(directory, path))
  case kind {
    check.MarkdownDocument -> check_markdown_file(path, text, context)
    check.ReleaseNotes -> check_release_notes(path, text, context)
    check.Changelog -> check.check_changelog(path, text, context)
    check.GleamSource -> check.check_gleam_source(path, text, context)
  }
}

/// Checks a Markdown document. The root README also has the guide badge
/// rules (see `check.check_readme`).
fn check_markdown_file(
  path: String,
  text: String,
  context: check.CheckContext,
) -> Report {
  case path == readme_path {
    True -> check.check_readme(path, text, context)
    False -> check.check_markdown(path, text, context)
  }
}

/// Checks the code blocks of release notes, and that they follow the
/// release notes template. A file whose name is not `release-<version>.md`
/// gets only one problem at line 1, because its version is not known.
fn check_release_notes(
  path: String,
  text: String,
  context: check.CheckContext,
) -> Report {
  case check.release_notes_version(path) {
    Ok(_version) -> check.check_release_notes(path, text, context)
    Error(Nil) ->
      Report(blocks_checked: 0, diff_blocks_checked: 0, problems: [
        check.Problem(file: path, line: 1, reason: check.MisnamedReleaseNotes),
      ])
  }
}

fn empty_report() -> Report {
  Report(blocks_checked: 0, diff_blocks_checked: 0, problems: [])
}

fn add_report(total: Report, report: Report) -> Report {
  Report(
    blocks_checked: total.blocks_checked + report.blocks_checked,
    diff_blocks_checked: total.diff_blocks_checked + report.diff_blocks_checked,
    problems: list.append(total.problems, report.problems),
  )
}

// ---------------------------------------------------------------------------
// Files
// ---------------------------------------------------------------------------

fn list_checked_files(
  directory: String,
  configuration: config.Config,
) -> Result(List(#(String, check.DocumentKind)), CheckError) {
  configuration.roots
  |> list.try_map(fn(root) {
    list_root_files(directory, root, configuration.checked_from_version)
  })
  |> result.map(list.flatten)
}

fn list_root_files(
  directory: String,
  root: CheckedRoot,
  checked_from_version: Version,
) -> Result(List(#(String, check.DocumentKind)), CheckError) {
  use is_directory <- result.try(is_directory(directory, root.path))
  case is_directory {
    True ->
      walk_directory(directory, root.path, root.kind, checked_from_version)
    False -> list_root_file(directory, root, checked_from_version)
  }
}

/// A root that is a file. A release notes file follows the rules of a file
/// in a directory root: it is skipped when its version is before
/// `checked_from_version`. It is kept when its name has no version, so that
/// `check_release_notes` reports the name.
fn list_root_file(
  directory: String,
  root: CheckedRoot,
  checked_from_version: Version,
) -> Result(List(#(String, check.DocumentKind)), CheckError) {
  use is_file <- result.try(
    simplifile.is_file(join(directory, root.path))
    |> result.map_error(ListFailed(root.path, _)),
  )
  case is_file, root.presence {
    True, _ -> Ok(keep_root_file(root, checked_from_version))
    False, MayBeMissing -> Ok([])
    False, MustExist -> Error(MissingRoot(root.path))
  }
}

fn keep_root_file(
  root: CheckedRoot,
  checked_from_version: Version,
) -> List(#(String, check.DocumentKind)) {
  let in_scope = case root.kind {
    check.ReleaseNotes ->
      check.release_notes_version(root.path) == Error(Nil)
      || check.is_checked_release_notes(root.path, checked_from_version)
    check.MarkdownDocument | check.GleamSource | check.Changelog -> True
  }
  case in_scope {
    True -> [#(root.path, root.kind)]
    False -> []
  }
}

fn is_directory(directory: String, path: String) -> Result(Bool, CheckError) {
  simplifile.is_directory(join(directory, path))
  |> result.map_error(ListFailed(path, _))
}

fn walk_directory(
  directory: String,
  path: String,
  kind: check.DocumentKind,
  checked_from_version: Version,
) -> Result(List(#(String, check.DocumentKind)), CheckError) {
  use names <- result.try(
    simplifile.read_directory(join(directory, path))
    |> result.map_error(ListFailed(path, _)),
  )
  names
  |> list.filter(fn(name) { !list.contains(skipped_directory_names, name) })
  |> list.sort(string.compare)
  |> list.try_map(fn(name) {
    walk_entry(directory, join(path, name), kind, checked_from_version)
  })
  |> result.map(list.flatten)
}

fn walk_entry(
  directory: String,
  path: String,
  kind: check.DocumentKind,
  checked_from_version: Version,
) -> Result(List(#(String, check.DocumentKind)), CheckError) {
  use is_directory <- result.try(is_directory(directory, path))
  case is_directory {
    True -> walk_directory(directory, path, kind, checked_from_version)
    False -> Ok(keep_if_kind(path, kind, checked_from_version))
  }
}

fn keep_if_kind(
  path: String,
  kind: check.DocumentKind,
  checked_from_version: Version,
) -> List(#(String, check.DocumentKind)) {
  let in_scope = case kind {
    check.ReleaseNotes ->
      check.is_checked_release_notes(path, checked_from_version)
    check.MarkdownDocument | check.GleamSource | check.Changelog -> True
  }
  case string.ends_with(path, file_extension(kind)) && in_scope {
    True -> [#(path, kind)]
    False -> []
  }
}

fn file_extension(kind: check.DocumentKind) -> String {
  case kind {
    check.MarkdownDocument | check.ReleaseNotes | check.Changelog -> ".md"
    check.GleamSource -> ".gleam"
  }
}
