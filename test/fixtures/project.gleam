//// Fixtures for the tests that read real files and run real git: small
//// projects written under `build/fixtures/`, each in its own directory,
//// and a git history with one tag.

import dream_snippets/git.{type GitError, Git}
import gleam/list
import gleam/result
import gleam/string
import simplifile

/// Writes a project with the files, each a path relative to the project
/// and its text, in `build/fixtures/<name>`. A directory left by an earlier
/// run is deleted first. Returns the project directory.
pub fn write_project(
  name: String,
  files: List(#(String, String)),
) -> Result(String, simplifile.FileError) {
  let directory = "build/fixtures/" <> name
  use Nil <- result.try(simplifile.delete_all([directory]))
  use Nil <- result.try(simplifile.create_directory_all(directory))
  use Nil <- result.try(
    list.try_each(files, fn(file) { write_file(directory, file) }),
  )
  Ok(directory)
}

fn write_file(
  directory: String,
  file: #(String, String),
) -> Result(Nil, simplifile.FileError) {
  let #(path, text) = file
  let full_path = directory <> "/" <> path
  let parent =
    full_path
    |> string.split("/")
    |> list.reverse
    |> list.drop(1)
    |> list.reverse
    |> string.join("/")
  use Nil <- result.try(simplifile.create_directory_all(parent))
  simplifile.write(to: full_path, contents: text)
}

/// Makes the directory a git repository with one commit of all its files
/// and the tag `tag` on that commit. Hooks and signing are turned off, so
/// the settings of the user cannot change the result.
pub fn commit_and_tag(directory: String, tag: String) -> Result(Nil, GitError) {
  let repository = Git(program: "git", directory:)
  use _output <- result.try(git.run(repository, ["init", "-q", "-b", "main"]))
  commit_again_and_tag(directory, tag)
}

/// Adds one more commit of all the files to the git repository that
/// `commit_and_tag` made, and the tag `tag` on that commit.
pub fn commit_again_and_tag(
  directory: String,
  tag: String,
) -> Result(Nil, GitError) {
  let repository = Git(program: "git", directory:)
  let settings = [
    "-c", "core.hooksPath=/dev/null", "-c", "commit.gpgSign=false", "-c",
    "tag.gpgSign=false", "-c", "user.name=Fixture", "-c",
    "user.email=fixture@example.com",
  ]
  use _output <- result.try(git.run(repository, ["add", "-A"]))
  use _output <- result.try(git.run(
    repository,
    list.append(settings, ["commit", "-q", "--no-verify", "-m", "Fixture"]),
  ))
  use _output <- result.try(git.run(
    repository,
    list.append(settings, ["tag", tag]),
  ))
  Ok(Nil)
}
