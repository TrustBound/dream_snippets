//// Tests for `dream_snippets/git`. They run the real git in a small
//// repository under `build/fixtures/`, with one commit tagged 1.0.0 and
//// one file changed after it.

import dream_snippets/check.{DiffHunk}
import dream_snippets/git.{Git, GitFailed, GitNotFound}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{type UnitNode, describe, group, it}
import fixtures/project
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import simplifile

const old_text = "pub fn name() {\n  \"old\"\n}\n"

const new_text = "pub fn name() {\n  \"new\"\n}\n"

pub fn tests() -> TestSuite {
  describe("dream_snippets/git", [
    tag_tests(),
    diff_tests(),
    file_at_tag_tests(),
    describe_tests(),
  ])
}

fn tag_tests() -> UnitNode {
  group("tag_exists", [
    it("finds a tag and not a tag that does not exist", fn() {
      // Arrange
      let assert Ok(directory) =
        project.write_project("git_tags", [#("src/app.gleam", old_text)])
      let assert Ok(Nil) = project.commit_and_tag(directory, "1.0.0")
      let repository = Git(program: "git", directory:)

      // Act
      let found =
        list.map(["1.0.0", "0.0.0-not-a-tag"], git.tag_exists(repository, _))

      // Assert
      found
      |> should
      |> be_equal([Ok(True), Ok(False)])
      |> or_fail_with("git should find 1.0.0 only")
    }),
    it("returns GitNotFound when the program is not on the PATH", fn() {
      // Arrange
      let repository =
        Git(program: "dream-snippets-no-such-program", directory: ".")

      // Act
      let found = git.tag_exists(repository, "1.0.0")

      // Assert
      found
      |> should
      |> be_equal(Error(GitNotFound))
      |> or_fail_with("A missing program should be an error")
    }),
  ])
}

fn diff_tests() -> UnitNode {
  group("diff_from_tag", [
    it("returns the diff of a file from a tag to the working tree", fn() {
      // Arrange
      let assert Ok(directory) =
        project.write_project("git_diff", [#("src/app.gleam", old_text)])
      let assert Ok(Nil) = project.commit_and_tag(directory, "1.0.0")
      let assert Ok(Nil) =
        simplifile.write(to: directory <> "/src/app.gleam", contents: new_text)
      let repository = Git(program: "git", directory:)

      // Act
      let hunks =
        git.diff_from_tag(repository, "1.0.0", "src/app.gleam")
        |> result.map(check.parse_hunks)

      // Assert
      hunks
      |> should
      |> be_equal(
        Ok([
          DiffHunk(header: "@@ -1,3 +1,3 @@", lines: [
            " pub fn name() {",
            "-  \"old\"",
            "+  \"new\"",
            " }",
          ]),
        ]),
      )
      |> or_fail_with("The diff should have one hunk with the change")
    }),
    it("returns GitFailed with the status when git fails", fn() {
      // Arrange
      let assert Ok(directory) =
        project.write_project("git_failure", [#("src/app.gleam", old_text)])
      let assert Ok(Nil) = project.commit_and_tag(directory, "1.0.0")
      let repository = Git(program: "git", directory:)

      // Act
      let result =
        git.run(repository, ["rev-parse", "--verify", "--quiet", "missing"])

      // Assert
      result
      |> should
      |> be_equal(Error(GitFailed(status: 1, output: "")))
      |> or_fail_with("A failed rev-parse should give its status")
    }),
  ])
}

fn file_at_tag_tests() -> UnitNode {
  group("file_at_tag", [
    it("returns a file as it was at the tag", fn() {
      // Arrange
      let assert Ok(directory) =
        project.write_project("git_file_at_tag", [#("src/app.gleam", old_text)])
      let assert Ok(Nil) = project.commit_and_tag(directory, "1.0.0")
      let assert Ok(Nil) =
        simplifile.write(to: directory <> "/src/app.gleam", contents: new_text)
      let repository = Git(program: "git", directory:)

      // Act
      let found = git.file_at_tag(repository, "1.0.0", "src/app.gleam")

      // Assert
      found
      |> should
      |> be_equal(Ok(Some(old_text)))
      |> or_fail_with("The text at the tag should be read, not the new text")
    }),
    it("returns None for a missing path and for a directory", fn() {
      // Arrange
      let assert Ok(directory) =
        project.write_project("git_file_at_tag_missing", [
          #("src/app.gleam", old_text),
        ])
      let assert Ok(Nil) = project.commit_and_tag(directory, "1.0.0")
      let repository = Git(program: "git", directory:)

      // Act
      let found =
        list.map(["src/other.gleam", "src", "src/app"], git.file_at_tag(
          repository,
          "1.0.0",
          _,
        ))

      // Assert
      found
      |> should
      |> be_equal([Ok(None), Ok(None), Ok(None)])
      |> or_fail_with("Only a file at exactly that path should be read")
    }),
    it("returns GitNotFound when the program is not on the PATH", fn() {
      // Arrange
      let repository =
        Git(program: "dream-snippets-no-such-program", directory: ".")

      // Act
      let found = git.file_at_tag(repository, "1.0.0", "src/app.gleam")

      // Assert
      found
      |> should
      |> be_equal(Error(GitNotFound))
      |> or_fail_with("A missing program should be an error")
    }),
  ])
}

fn describe_tests() -> UnitNode {
  group("describe_error", [
    it("describes each git error in a few words", fn() {
      // Arrange
      let errors = [GitNotFound, GitFailed(status: 128, output: "x")]

      // Act
      let descriptions = list.map(errors, git.describe_error)

      // Assert
      descriptions
      |> should
      |> be_equal([
        "git is not on the PATH",
        "git stopped with exit status 128",
      ])
      |> or_fail_with("Each error should have its description")
    }),
  ])
}
