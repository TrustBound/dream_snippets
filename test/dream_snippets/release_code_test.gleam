//// Tests for the release that a block belongs to in `dream_snippets/check`:
//// the blocks of a changelog section of an older release are compared
//// with the files at its tag, and its diffs end at its tag. The files at
//// the tags and the diffs are held in `fixtures/check_context` (dream at
//// 3.0.0, with the tags 2.3.0 and 2.4.1), so the tests never read a real
//// history.

import dream_snippets/check.{
  CheckContext, FilesAtTag, GitUnavailable, MissingFileAtTag, MissingReleaseTag,
  NoDiffForPath, NotAnOlderRelease, Problem, ReleaseNotBeforeVersion, Report,
  UnsafeOldCodeLink, Version, WorkingTree, WrongTag,
}
import dream_snippets/git.{GitFailed, GitNotFound}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{type UnitNode, describe, group, it}
import fixtures/check_context.{
  badge_end, context, diff_file_header, diff_heading, diff_path, document,
  gleam_document, old_code_heading_with, project,
}
import gleam/list

/// The context of the fixtures, with every changelog section checked.
fn all_sections_context() -> check.CheckContext {
  CheckContext(..context(), checked_from_version: Version(0, 0, 0, []))
}

/// A heading with the tested snippet badge that links to `target` (a path
/// and an optional anchor) at `tag`.
fn heading_at(tag: String, target: String) -> String {
  "### Example <a href=\"https://github.com/TrustBound/dream/blob/"
  <> tag
  <> "/"
  <> target
  <> badge_end
}

/// A changelog with one section, `## [<name>]`, at line 1. Its lines start
/// at line 3.
fn changelog(name: String, lines: List(String)) -> String {
  document(["## [" <> name <> "] - 2026-01-01", "", ..lines])
}

fn check_section(name: String, lines: List(String)) -> List(check.Problem) {
  check.check_changelog(
    "CHANGELOG.md",
    changelog(name, lines),
    all_sections_context(),
  ).problems
}

fn check_section_with(
  name: String,
  lines: List(String),
  with_context: check.CheckContext,
) -> List(check.Problem) {
  check.check_changelog("CHANGELOG.md", changelog(name, lines), with_context).problems
}

pub fn tests() -> TestSuite {
  describe("dream_snippets/check release of a document", [
    snippet_tests(),
    diff_tests(),
    old_code_tests(),
    section_tests(),
    message_tests(),
  ])
}

fn snippet_tests() -> UnitNode {
  group("a tested snippet in the section of an older release", [
    it("passes a block that is the file at the tag", fn() {
      // Arrange
      let lines =
        gleam_document(heading_at("2.4.1", "src/old.gleam#L1-L2"), [
          "pub fn upload(request) {", "  case request.stream {",
        ])

      // Act
      let problems = check_section("2.4.1", lines)

      // Assert
      problems
      |> should
      |> be_equal([])
      |> or_fail_with("The block is lines 1 to 2 of src/old.gleam at 2.4.1")
    }),
    it("fails a file that the tag does not have", fn() {
      // Arrange
      let lines = gleam_document(heading_at("2.4.1", "src/new.gleam"), ["x"])

      // Act
      let problems = check_section("2.4.1", lines)

      // Assert
      problems
      |> should
      |> be_equal([
        Problem("CHANGELOG.md", 5, MissingFileAtTag("src/new.gleam", "2.4.1")),
      ])
      |> or_fail_with("src/new.gleam is not at the tag 2.4.1")
    }),
    it("fails a path that the check does not give to git", fn() {
      // Arrange
      let lines = gleam_document(heading_at("2.4.1", "src/$old.gleam"), ["x"])

      // Act
      let problems = check_section("2.4.1", lines)

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(
          "CHANGELOG.md",
          5,
          UnsafeOldCodeLink(tag: "2.4.1", path: "src/$old.gleam"),
        ),
      ])
      |> or_fail_with("A $ is not given to git")
    }),
    it("fails when git cannot read the file at the tag", fn() {
      // Arrange
      let failing =
        CheckContext(..all_sections_context(), file_at_tag: fn(_tag, _path) {
          Error(GitFailed(status: 128, output: ""))
        })
      let lines = gleam_document(heading_at("2.4.1", "src/old.gleam"), ["x"])

      // Act
      let problems = check_section_with("2.4.1", lines, failing)

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(
          "CHANGELOG.md",
          5,
          GitUnavailable(GitFailed(status: 128, output: "")),
        ),
      ])
      |> or_fail_with("A git failure should be the problem")
    }),
    it("fails when git cannot look up the tag of the release", fn() {
      // Arrange
      let no_git =
        CheckContext(..all_sections_context(), tag_exists: fn(_tag) {
          Error(GitNotFound)
        })
      let lines = gleam_document(heading_at("2.4.1", "src/old.gleam"), ["x"])

      // Act
      let problems = check_section_with("2.4.1", lines, no_git)

      // Assert
      problems
      |> should
      |> be_equal([Problem("CHANGELOG.md", 5, GitUnavailable(GitNotFound))])
      |> or_fail_with("A missing git should be the problem")
    }),
    it("fails a link at the version in gleam.toml", fn() {
      // Arrange
      let lines =
        gleam_document(heading_at("3.0.0", "src/old.gleam#L1"), [
          "pub fn upload(request) {",
        ])

      // Act
      let problems = check_section("2.4.1", lines)

      // Assert
      problems
      |> should
      |> be_equal([
        Problem("CHANGELOG.md", 5, WrongTag(found: "3.0.0", expected: "2.4.1")),
      ])
      |> or_fail_with("The section links at its own release")
    }),
  ])
}

fn diff_tests() -> UnitNode {
  group("a diff in the section of an older release", [
    it("passes lines of the diff between the two tags", fn() {
      // Arrange
      let lines =
        list.flatten([
          [diff_heading("2.3.0...2.4.1", diff_path), "", "```diff"],
          diff_file_header(diff_path),
          [
            "-import gleam/option.{type Option}",
            "+import gleam/option.{None, Some}",
          ],
          ["```"],
        ])

      // Act
      let problems = check_section("2.4.1", lines)

      // Assert
      problems
      |> should
      |> be_equal([])
      |> or_fail_with("The lines are in the diff from 2.3.0 to 2.4.1")
    }),
    it("fails a file with no change between the two tags", fn() {
      // Arrange
      let lines =
        list.flatten([
          [diff_heading("2.3.0...2.4.1", "src/same.gleam"), "", "```diff"],
          diff_file_header("src/same.gleam"),
          ["-old"],
          ["```"],
        ])

      // Act
      let problems = check_section("2.4.1", lines)

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(
          "CHANGELOG.md",
          5,
          NoDiffForPath(
            path: "src/same.gleam",
            old_tag: "2.3.0",
            new_side: FilesAtTag("2.4.1"),
          ),
        ),
      ])
      |> or_fail_with("src/same.gleam did not change between the tags")
    }),
  ])
}

fn old_code_tests() -> UnitNode {
  group("code at an older release in release notes of an older release", [
    it("fails code at the release of the notes", fn() {
      // Arrange
      let heading =
        old_code_heading_with("2.4.1", "2.4.1", "2.4.1", "src/old.gleam")
      let notes = document(gleam_document(heading, ["x"]))

      // Act
      let problems =
        check.check_release_notes(
          "releases/release-2.4.1.md",
          notes,
          all_sections_context(),
        ).problems
        |> list.take(1)

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(
          "releases/release-2.4.1.md",
          3,
          NotAnOlderRelease(tag: "2.4.1", version: "2.4.1"),
        ),
      ])
      |> or_fail_with("Old code must come before the release of the notes")
    }),
  ])
}

fn section_tests() -> UnitNode {
  group("the sections of the changelog", [
    it("does not start a section at a heading in a code fence", fn() {
      // Arrange
      let text =
        document([
          "## [Unreleased]", "", "```markdown", "## [1.0.0]", "```", "",
          "```gleam", "x", "```",
        ])

      // Act
      let report = check.check_changelog("CHANGELOG.md", text, context())

      // Assert
      report
      |> should
      |> be_equal(
        Report(blocks_checked: 1, diff_blocks_checked: 0, problems: [
          Problem("CHANGELOG.md", 7, check.MissingBadgeHeading),
        ]),
      )
      |> or_fail_with("The gleam block is in the Unreleased section")
    }),
    it("fails the blocks of a section of a release after the version", fn() {
      // Arrange
      let lines = gleam_document(heading_at("3.1.0", "src/old.gleam"), ["x"])

      // Act
      let problems = check_section("3.1.0", lines)

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(
          "CHANGELOG.md",
          5,
          ReleaseNotBeforeVersion(release: "3.1.0", version: "3.0.0"),
        ),
      ])
      |> or_fail_with("3.1.0 is after the version 3.0.0")
    }),
    it("fails the blocks of a section whose tag is not in the clone", fn() {
      // Arrange
      let lines = gleam_document(heading_at("2.0.0", "src/old.gleam"), ["x"])

      // Act
      let problems = check_section("2.0.0", lines)

      // Assert
      problems
      |> should
      |> be_equal([Problem("CHANGELOG.md", 5, MissingReleaseTag("2.0.0"))])
      |> or_fail_with("The tag 2.0.0 is not in the fake clone")
    }),
  ])
}

fn message_tests() -> UnitNode {
  group("the messages of the release of a document", [
    it("describes each reason of an older release", fn() {
      // Arrange
      let reasons = [
        WrongTag(found: "3.0.0", expected: "2.4.1"),
        NotAnOlderRelease(tag: "2.4.1", version: "2.4.1"),
        NoDiffForPath("src/app.gleam", "2.3.0", FilesAtTag("2.4.1")),
        NoDiffForPath("src/app.gleam", "2.4.1", WorkingTree),
        check.DiffLineNotFound("src/app.gleam", "2.3.0", FilesAtTag("2.4.1")),
        MissingReleaseTag("2.4.1"),
        ReleaseNotBeforeVersion(release: "3.1.0", version: "3.0.0"),
      ]

      // Act
      let messages =
        list.map(reasons, fn(reason) {
          check.describe_reason(reason, project())
        })

      // Assert
      messages
      |> should
      |> be_equal([
        "the badge link uses the tag 3.0.0, but this file must link at the tag 2.4.1 (release notes and changelog sections link at the tag of their own release)",
        "the tag 2.4.1 is not a release before 2.4.1, the release of these release notes, so use the tested snippet badge for this code",
        "src/app.gleam has no changes between the tags 2.3.0 and 2.4.1",
        "src/app.gleam has no changes since the tag 2.4.1",
        "this line is not in \"git diff 2.3.0 2.4.1 -- src/app.gleam\" at this place; a diff block shows lines of the real diff, in order and contiguous within a hunk",
        "this block is in the docs of the release 2.4.1, so it is compared with the files at the tag 2.4.1, but that tag is not in this clone; fetch the tags with \"git fetch --tags\" (a shallow clone has none)",
        "this block is in the docs of the release 3.1.0, which is neither 3.0.0, the version in gleam.toml, nor a release before it; set the version in gleam.toml to the release that these docs are for",
      ])
      |> or_fail_with("Each reason should have its message")
    }),
    it("shows other control characters as hexadecimal escapes", fn() {
      // Act
      let line = check.one_line("a\u{1B}[31mb\u{85}c\u{7F}")

      // Assert
      line
      |> should
      |> be_equal("a\\u{1B}[31mb\\u{85}c\\u{7F}")
      |> or_fail_with("Each control character should be visible")
    }),
  ])
}
