//// Tests for the blocks of code at an older release in
//// `dream_snippets/check`. The file at the old tag and the tags of the
//// clone are held in `fixtures/check_context`, so the tests never read a
//// real history.

import dream_snippets/check.{
  type Problem, CheckContext, ForeignLink, GitUnavailable, LineRangePastEnd,
  MalformedLineRange, MalformedOldCodeBadge, MissingFileAtTag, MissingOldTag,
  NotAnOlderRelease, OldCodeBadgeWithOtherBadge, OldCodeDiffers,
  OldCodeNotAllowed, Problem, Report, SnippetLink, UnsafeOldCodeLink,
}
import dream_snippets/git.{GitFailed, GitNotFound}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{type UnitNode, describe, group, it}
import fixtures/check_context.{
  context, diff_file_header, diff_heading, diff_path, document, gleam_document,
  old_code_heading, old_code_heading_with, old_code_path, project,
}
import gleam/list
import gleam/string

const guide_file = "docs/guides/upgrading.md"

/// The lines of `old_code_source`, without the final newline.
const old_lines = [
  "pub fn upload(request) {", "  case request.stream {",
  "    Some(chunks) -> save(chunks)", "  }", "}",
]

/// Release notes of dream 3.0.0 that follow the release notes template.
const release_notes =
  "# Dream 3.0.0 Release Notes

**Release Date:** 2026-11-20

## Key Highlights

## What's New

## Testing

## Upgrading

### Migration Guide

## Documentation

## Community
"

pub fn tests() -> TestSuite {
  describe("dream_snippets/check code at an older release", [
    passing_tests(),
    place_tests(),
    badge_tests(),
    tag_tests(),
    file_tests(),
    parse_tests(),
    describe_tests(),
  ])
}

/// Checks the lines as a guide with the fake context.
fn check_guide(lines: List(String)) -> List(Problem) {
  check.check_markdown(guide_file, document(lines), context()).problems
}

fn passing_tests() -> UnitNode {
  group("passing blocks", [
    it("passes a guide block that is the whole file at the old tag", fn() {
      // Arrange
      let lines = gleam_document(old_code_heading(old_code_path), old_lines)

      // Act
      let report = check.check_markdown(guide_file, document(lines), context())

      // Assert
      report
      |> should
      |> be_equal(
        Report(
          ..check.empty_report(),
          blocks_checked: 1,
          diff_blocks_checked: 0,
          problems: [],
        ),
      )
      |> or_fail_with("The whole file at 2.4.1 should pass")
    }),
    it("passes a guide block that is a line range at the old tag", fn() {
      // Arrange
      let lines =
        gleam_document(old_code_heading(old_code_path <> "#L2-L4"), [
          "  case request.stream {",
          "    Some(chunks) -> save(chunks)",
          "  }",
        ])

      // Act
      let problems = check_guide(lines)

      // Assert
      problems
      |> should
      |> be_equal([])
      |> or_fail_with("Lines 2 to 4 at 2.4.1 should pass")
    }),
    it("passes a block in release notes", fn() {
      // Arrange
      let notes =
        release_notes
        <> "\n"
        <> document(gleam_document(old_code_heading(old_code_path), old_lines))

      // Act
      let report =
        check.check_release_notes("releases/release-3.0.0.md", notes, context())

      // Assert
      report
      |> should
      |> be_equal(
        Report(
          ..check.empty_report(),
          blocks_checked: 1,
          diff_blocks_checked: 0,
          problems: [],
        ),
      )
      |> or_fail_with("Release notes can show code at an older release")
    }),
    it("passes a tag with a -, doubled in the image address", fn() {
      // Arrange
      let with_tag =
        CheckContext(..context(), tag_exists: fn(tag) {
          Ok(tag == "2.4.1-rc-1")
        })
      let heading =
        old_code_heading_with("2.4.1-rc-1", "2.4.1-rc-1", "2.4.1--rc--1", "x")
      let lines = gleam_document(heading, ["x"])

      // Act
      let problems =
        check.check_markdown(guide_file, document(lines), with_tag).problems

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(guide_file, 3, MissingFileAtTag(path: "x", tag: "2.4.1-rc-1")),
      ])
      |> or_fail_with("The badge should pass, and the file is then looked up")
    }),
    it("reads a tag with a _, doubled in the image address", fn() {
      // Arrange
      let heading =
        old_code_heading_with("2.4.1-rc_1", "2.4.1-rc_1", "2.4.1--rc__1", "x")
      let lines = gleam_document(heading, ["x"])

      // Act
      let problems =
        check.check_markdown(guide_file, document(lines), context()).problems

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(guide_file, 3, NotAnOlderRelease("2.4.1-rc_1", "3.0.0")),
      ])
      |> or_fail_with("The badge should pass; rc_1 is not a semver pre-release")
    }),
  ])
}

fn place_tests() -> UnitNode {
  let block = gleam_document(old_code_heading(old_code_path), old_lines)
  let not_allowed = [Problem("x", 3, OldCodeNotAllowed(["docs/guides"]))]
  group("where the badge is allowed", [
    it("fails in a Markdown document that is not a guide", fn() {
      // Act
      let problems =
        check.check_markdown("x", document(block), context()).problems

      // Assert
      problems
      |> should
      |> be_equal(not_allowed)
      |> or_fail_with("Only guides and release notes can show old code")
    }),
    it("fails in the README", fn() {
      // Act
      let problems =
        check.check_readme("README.md", document(block), context()).problems

      // Assert
      problems
      |> should
      |> be_equal([
        Problem("README.md", 3, OldCodeNotAllowed(["docs/guides"])),
      ])
      |> or_fail_with("The README shows only current code")
    }),
    it("fails in a checked changelog section", fn() {
      // Act
      let problems =
        check.check_changelog("x", document(block), context()).problems

      // Assert
      problems
      |> should
      |> be_equal(not_allowed)
      |> or_fail_with("The changelog shows only current code")
    }),
    it("fails in a doc comment", fn() {
      // Arrange
      let source =
        block
        |> list.map(fn(line) { string.trim_end("/// " <> line) })
        |> document

      // Act
      let problems = check.check_gleam_source("x", source, context()).problems

      // Assert
      problems
      |> should
      |> be_equal(not_allowed)
      |> or_fail_with("Doc comments show only current code")
    }),
  ])
}

fn badge_tests() -> UnitNode {
  group("the badge", [
    it("fails a badge with another image address", fn() {
      // Arrange
      let heading = old_code_heading_with("2.4.1", "2.4.1", "2.4.1-x", "x")

      // Act
      let problems = check_guide(gleam_document(heading, ["x"]))

      // Assert
      problems
      |> should
      |> be_equal([Problem(guide_file, 3, MalformedOldCodeBadge)])
      |> or_fail_with("The image must hold the tag of the link")
    }),
    it("fails a badge whose alt text names another tag", fn() {
      // Arrange
      let heading = old_code_heading_with("2.4.1", "2.4.0", "2.4.1", "x")

      // Act
      let problems = check_guide(gleam_document(heading, ["x"]))

      // Assert
      problems
      |> should
      |> be_equal([Problem(guide_file, 3, MalformedOldCodeBadge)])
      |> or_fail_with("The alt text must name the tag of the link")
    }),
    it("fails a heading with no title", fn() {
      // Arrange
      let heading =
        string.replace(old_code_heading(old_code_path), "### Before", "###")

      // Act
      let problems = check_guide(gleam_document(heading, old_lines))

      // Assert
      problems
      |> should
      |> be_equal([Problem(guide_file, 3, MalformedOldCodeBadge)])
      |> or_fail_with("The heading needs a title")
    }),
    it("fails a line that is not a heading", fn() {
      // Arrange
      let line =
        string.replace(old_code_heading(old_code_path), "### Before", "Before")

      // Act
      let problems = check_guide(gleam_document(line, old_lines))

      // Assert
      problems
      |> should
      |> be_equal([Problem(guide_file, 3, MalformedOldCodeBadge)])
      |> or_fail_with("The badge must end a heading")
    }),
    it("fails a badge with no link", fn() {
      // Arrange
      let heading = "### Before <img alt=\"Code at 2.4.1\">"

      // Act
      let problems = check_guide(gleam_document(heading, old_lines))

      // Assert
      problems
      |> should
      |> be_equal([Problem(guide_file, 3, MalformedOldCodeBadge)])
      |> or_fail_with("The badge must be a link")
    }),
    it("fails a badge whose link has no closing quote", fn() {
      // Arrange
      let heading = "### alt=\"Code at 2.4.1 <a href=\"x"

      // Act
      let problems = check_guide(gleam_document(heading, old_lines))

      // Assert
      problems
      |> should
      |> be_equal([Problem(guide_file, 3, MalformedOldCodeBadge)])
      |> or_fail_with("The link address must end with a quote")
    }),
    it("fails a heading with the badge and a guide badge", fn() {
      // Arrange
      let heading =
        old_code_heading(old_code_path)
        <> " <a href=\"https://github.com/TrustBound/dream/blob/3.0.0/docs/guides/example.md#example-\"><img align=\"right\" alt=\"Guide: Example guide\" title=\"Guide: Example guide\" src=\"https://img.shields.io/badge/%F0%9F%93%96_read-guide-blue.svg?style=flat-square\"></a>"

      // Act
      let problems = check_guide(gleam_document(heading, old_lines))

      // Assert
      problems
      |> should
      |> be_equal([Problem(guide_file, 3, OldCodeBadgeWithOtherBadge)])
      |> or_fail_with("The badge must be the only badge")
    }),
    it("fails a diff heading with the badge and the diff badge", fn() {
      // Arrange
      let heading =
        string.replace(
          diff_heading("2.4.1...3.0.0", diff_path),
          "### Change",
          old_code_heading(old_code_path),
        )
      let lines =
        list.flatten([
          [heading, "", "```diff"],
          diff_file_header(diff_path),
          ["-  case request.stream {", "```"],
        ])

      // Act
      let problems = check_guide(lines)

      // Assert
      problems
      |> should
      |> be_equal([Problem(guide_file, 3, OldCodeBadgeWithOtherBadge)])
      |> or_fail_with("A diff heading must not have the badge too")
    }),
    it("fails a link to another repository", fn() {
      // Arrange
      let heading =
        string.replace(
          old_code_heading(old_code_path),
          "TrustBound/dream/",
          "someone/dream/",
        )

      // Act
      let problems = check_guide(gleam_document(heading, old_lines))

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(
          guide_file,
          3,
          ForeignLink(
            "https://github.com/someone/dream/blob/2.4.1/src/old.gleam",
          ),
        ),
      ])
      |> or_fail_with("The link must point into the repository")
    }),
  ])
}

fn tag_tests() -> UnitNode {
  group("the old tag", [
    it("fails a tag with characters that git does not get", fn() {
      // Arrange
      let heading = old_code_heading_with("2.4.1~1", "2.4.1~1", "2.4.1~1", "x")

      // Act
      let problems = check_guide(gleam_document(heading, ["x"]))

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(guide_file, 3, UnsafeOldCodeLink(tag: "2.4.1~1", path: "x")),
      ])
      |> or_fail_with("An unsafe tag must not reach git")
    }),
    it("fails a path with characters that git does not get", fn() {
      // Arrange
      let heading = old_code_heading("src/a%20b.gleam")

      // Act
      let problems = check_guide(gleam_document(heading, ["x"]))

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(
          guide_file,
          3,
          UnsafeOldCodeLink(tag: "2.4.1", path: "src/a%20b.gleam"),
        ),
      ])
      |> or_fail_with("An unsafe path must not reach git")
    }),
    it("fails the tag of the current version", fn() {
      // Arrange
      let heading = old_code_heading_with("3.0.0", "3.0.0", "3.0.0", "x")

      // Act
      let problems = check_guide(gleam_document(heading, ["x"]))

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(
          guide_file,
          3,
          NotAnOlderRelease(tag: "3.0.0", version: "3.0.0"),
        ),
      ])
      |> or_fail_with(
        "Code of the current version has the tested snippet badge",
      )
    }),
    it("fails a tag that is not a release version", fn() {
      // Arrange
      let heading = old_code_heading_with("main", "main", "main", "x")

      // Act
      let problems = check_guide(gleam_document(heading, ["x"]))

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(guide_file, 3, NotAnOlderRelease(tag: "main", version: "3.0.0")),
      ])
      |> or_fail_with("A branch name is not an older release")
    }),
    it("fails a tag that is not in the clone", fn() {
      // Arrange
      let heading = old_code_heading_with("2.4.0", "2.4.0", "2.4.0", "x")

      // Act
      let problems = check_guide(gleam_document(heading, ["x"]))

      // Assert
      problems
      |> should
      |> be_equal([Problem(guide_file, 3, MissingOldTag("2.4.0"))])
      |> or_fail_with("The tag must be in the clone")
    }),
    it("fails when git cannot look for the tag", fn() {
      // Arrange
      let no_git =
        CheckContext(..context(), tag_exists: fn(_tag) { Error(GitNotFound) })
      let lines = gleam_document(old_code_heading(old_code_path), old_lines)

      // Act
      let problems =
        check.check_markdown(guide_file, document(lines), no_git).problems

      // Assert
      problems
      |> should
      |> be_equal([Problem(guide_file, 3, GitUnavailable(GitNotFound))])
      |> or_fail_with("A git failure should be a problem")
    }),
  ])
}

fn file_tests() -> UnitNode {
  group("the file at the old tag", [
    it("fails a malformed line anchor", fn() {
      // Arrange
      let heading = old_code_heading(old_code_path <> "#L2-4")

      // Act
      let problems = check_guide(gleam_document(heading, old_lines))

      // Assert
      problems
      |> should
      |> be_equal([Problem(guide_file, 3, MalformedLineRange("#L2-4"))])
      |> or_fail_with("The anchor must be #L<start>-L<end>")
    }),
    it("fails a path that is not a file at the tag", fn() {
      // Arrange
      let heading = old_code_heading("src/new.gleam")

      // Act
      let problems = check_guide(gleam_document(heading, old_lines))

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(
          guide_file,
          3,
          MissingFileAtTag(path: "src/new.gleam", tag: "2.4.1"),
        ),
      ])
      |> or_fail_with("The file must exist at the tag")
    }),
    it("fails when git cannot read the file", fn() {
      // Arrange
      let failing =
        CheckContext(..context(), file_at_tag: fn(_tag, _path) {
          Error(GitFailed(status: 128, output: ""))
        })
      let lines = gleam_document(old_code_heading(old_code_path), old_lines)

      // Act
      let problems =
        check.check_markdown(guide_file, document(lines), failing).problems

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(
          guide_file,
          3,
          GitUnavailable(GitFailed(status: 128, output: "")),
        ),
      ])
      |> or_fail_with("A git failure should be a problem")
    }),
    it("fails a line range past the end of the file at the tag", fn() {
      // Arrange
      let heading = old_code_heading(old_code_path <> "#L4-L9")

      // Act
      let problems = check_guide(gleam_document(heading, ["  }", "}"]))

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(guide_file, 3, LineRangePastEnd(end: 9, line_count: 5)),
      ])
      |> or_fail_with("The file at 2.4.1 has 5 lines")
    }),
    it("fails a block that is not the same as the lines at the tag", fn() {
      // Arrange
      let heading = old_code_heading(old_code_path <> "#L1-L2")

      // Act
      let problems =
        check_guide(
          gleam_document(heading, [
            "pub fn upload(request) {",
            "  case request.body {",
          ]),
        )

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(
          guide_file,
          3,
          OldCodeDiffers(
            path: old_code_path,
            anchor: "#L1-L2",
            tag: "2.4.1",
            first_difference_line: 5,
          ),
        ),
      ])
      |> or_fail_with("The second line of the block differs")
    }),
  ])
}

fn parse_tests() -> UnitNode {
  group("parse_old_code_heading", [
    it("reads the tag, the path and the anchor", fn() {
      // Act
      let link =
        check.parse_old_code_heading(
          old_code_heading(old_code_path <> "#L2-L4"),
          project().repository,
        )

      // Assert
      link
      |> should
      |> be_equal(
        Ok(SnippetLink(tag: "2.4.1", path: old_code_path, anchor: "#L2-L4")),
      )
      |> or_fail_with("The link should be read")
    }),
  ])
}

fn describe_tests() -> UnitNode {
  group("describe_reason", [
    it("describes every reason of code at an older release", fn() {
      // Arrange
      let reasons = [
        MalformedOldCodeBadge,
        OldCodeBadgeWithOtherBadge,
        OldCodeNotAllowed(["docs/guides", "guides"]),
        UnsafeOldCodeLink(tag: "2.4.1~1", path: "src/old.gleam"),
        NotAnOlderRelease(tag: "3.0.0", version: "3.0.0"),
        MissingFileAtTag(path: "src/new.gleam", tag: "2.4.1"),
        OldCodeDiffers(
          path: old_code_path,
          anchor: "#L1-L2",
          tag: "2.4.1",
          first_difference_line: 5,
        ),
      ]

      // Act
      let descriptions = list.map(reasons, check.describe_reason(_, project()))

      // Assert
      descriptions
      |> should
      |> be_equal([
        "the code at an older release badge is not in the exact format, or the tag in its alt text or image is not the tag of its link; copy it from docs/contributing/contributing.md",
        "this heading has the code at an older release badge and another badge, but a heading with that badge has no other badge",
        "the code at an older release badge is only allowed in the guides under docs/guides or guides and in release notes, because the README, the changelog and doc comments show only code of the current version",
        "the tag 2.4.1~1 or the path src/old.gleam has characters that the check does not give to git (a tag has only letters, digits and . _ -, and a path also /)",
        "the tag 3.0.0 is not a release before 3.0.0, the version in gleam.toml, so use the tested snippet badge for this code",
        "the badge links to src/new.gleam, which is not a file at the tag 2.4.1",
        "the code block is not the same as src/old.gleam#L1-L2 at the tag 2.4.1; the first difference is at line 5",
      ])
      |> or_fail_with("Each reason should have its message")
    }),
  ])
}
