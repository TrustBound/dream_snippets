//// The example project of the guides: `my_app` 0.1.0, in the GitHub
//// repository `me/my_app`. Each test writes the files of one step under
//// `build/fixtures/` and checks them as the command does.

import dream_snippets.{type Output}
import fixtures/project
import gleam/list
import gleam/result
import gleam/string
import simplifile

/// The `gleam.toml` of the example project, with no settings. The guides
/// show this file.
pub fn gleam_toml() -> String {
  read("test/fixtures/my_app/gleam.toml")
}

/// The main module of the example project.
pub const main_module = "pub fn main() -> Nil {\n  Nil\n}\n"

/// The start of a tested snippet badge, before the link address.
pub const snippet_badge_start = " <a href=\""

/// The text of a tested snippet badge after its link address.
pub const snippet_badge_end =
  "\"><img align=\"right\" alt=\"Tested snippet\" src=\"https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square\"></a>"

/// The text of a guide badge after its link address.
pub const guide_badge_end =
  "\"><img align=\"right\" alt=\"Guide: Getting started\" title=\"Guide: Getting started\" src=\"https://img.shields.io/badge/%F0%9F%93%96_read-guide-blue.svg?style=flat-square\"></a>"

/// Writes the example project with `gleam.toml`, `src/my_app.gleam` and
/// the files, and checks it. A file in `files` with the path of a base
/// file takes its place. Returns what the command prints.
pub fn check(name: String, files: List(#(String, String))) -> Output {
  let base = [#("gleam.toml", gleam_toml()), #("src/my_app.gleam", main_module)]
  let paths = list.map(files, fn(file) { file.0 })
  let kept = list.filter(base, fn(file) { !list.contains(paths, file.0) })
  let assert Ok(directory) =
    project.write_project("guide_" <> name, list.append(kept, files))
  dream_snippets.output(dream_snippets.check_project(directory))
}

/// What the command prints for an output: each line of the standard
/// output, then each line of the standard error, each with a line break.
/// An output file of a guide holds this text.
pub fn printed(output: Output) -> String {
  list.append(output.standard_output, output.standard_error)
  |> list.map(fn(line) { line <> "\n" })
  |> string.concat
}

/// Reads the output file `test/outputs/<name>.txt`, which a guide shows.
pub fn output_file(name: String) -> String {
  read("test/outputs/" <> name <> ".txt")
}

/// Reads a file of this repository, or returns an empty string.
pub fn read(path: String) -> String {
  simplifile.read(path) |> result.unwrap("")
}
