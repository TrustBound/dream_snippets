//// Tests for `dream_snippets/check`, which fails when a Gleam code block in
//// the docs is not backed by tested code, or a diff block is not a real
//// excerpt of the git diff.
////
//// Each fixture is a small inline document. The linked snippet files and
//// the git history are held in `fixtures/check_context`, so the tests never
//// read real docs, snippets or history.

import dream_snippets/check.{
  AlphanumericIdentifier, BlockDiffers, CheckContext, DiffHunk, DiffLineNotFound,
  EmptyDiffBlock, ForeignLink, GitHubRepository, GitUnavailable, HiddenGleamCode,
  HunkHeaderNotFound, LineRangePastEnd, MalformedBadge, MalformedDiffBadge,
  MalformedLineRange, MissingBadgeHeading, MissingDiffBadgeHeading,
  MissingDiffFileHeader, MissingFile, MissingOldTag, NoDiffForPath,
  NotCompareLink, NumericIdentifier, OldTestedSourceLine, Problem, Project,
  ReleaseNotesTitleMismatch, Report, ReversedLineRange, SnippetLink,
  UnclosedFence, UnreadableFile, Version, WholeFile, WorkingTree,
  WrongDiffAnchor, WrongNewTag, WrongTag,
}
import dream_snippets/git.{GitFailed, GitNotFound}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{type UnitNode, describe, group, it}
import fixtures/check_context.{
  check, context, diff_document, diff_file_header, diff_heading, diff_path,
  diff_report, document, heading, main_function, odd_diff, odd_diff_path,
  plain_snippet_path, project, snippet_path, snippet_source, tight_snippet_path,
  unreadable_path,
}
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import simplifile

pub fn tests() -> TestSuite {
  describe("dream_snippets/check", [
    passing_tests(),
    failing_tests(),
    diff_passing_tests(),
    diff_failing_tests(),
    scope_tests(),
    report_tests(),
    digest_tests(),
    version_tests(),
    precedence_tests(),
    one_line_tests(),
    summary_tests(),
    fence_tests(),
    heading_tests(),
    link_tests(),
    snippet_file_tests(),
    more_diff_tests(),
    describe_tests(),
  ])
}

/// The order of two version texts, or `Error(Nil)` when one is not a
/// version.
fn precedence(first: String, second: String) -> Result(order.Order, Nil) {
  case check.parse_release_version(first), check.parse_release_version(second) {
    Ok(first_version), Ok(second_version) ->
      Ok(check.compare_versions(first_version, second_version))
    _, _ -> Error(Nil)
  }
}

fn precedence_tests() -> UnitNode {
  group("semver precedence", [
    it("puts a pre-release before its release", fn() {
      // Act
      let found = precedence("2.0.0-rc.1", "2.0.0")

      // Assert
      found
      |> should
      |> be_equal(Ok(order.Lt))
      |> or_fail_with("2.0.0-rc.1 should come before 2.0.0")
    }),
    it("puts a pre-release after the release before it", fn() {
      // Act
      let found = precedence("2.0.0-alpha", "1.9.9")

      // Assert
      found
      |> should
      |> be_equal(Ok(order.Gt))
      |> or_fail_with("2.0.0-alpha should come after 1.9.9")
    }),
    it("compares numeric identifiers as numbers", fn() {
      // Act
      let found = precedence("1.0.0-beta.2", "1.0.0-beta.11")

      // Assert
      found
      |> should
      |> be_equal(Ok(order.Lt))
      |> or_fail_with("beta.2 should come before beta.11")
    }),
    it("compares alphanumeric identifiers in ASCII order", fn() {
      // Act
      let found = precedence("1.0.0-Beta", "1.0.0-alpha")

      // Assert
      found
      |> should
      |> be_equal(Ok(order.Lt))
      |> or_fail_with("B (66) should come before a (97)")
    }),
    it("puts a numeric identifier before an alphanumeric one", fn() {
      // Act
      let found = precedence("1.0.0-alpha.1", "1.0.0-alpha.beta")

      // Assert
      found
      |> should
      |> be_equal(Ok(order.Lt))
      |> or_fail_with("alpha.1 should come before alpha.beta")
    }),
    it("puts an alphanumeric identifier after a numeric one", fn() {
      // Act
      let found = precedence("1.0.0-alpha.beta", "1.0.0-alpha.1")

      // Assert
      found
      |> should
      |> be_equal(Ok(order.Gt))
      |> or_fail_with("alpha.beta should come after alpha.1")
    }),
    it("puts the shorter list of equal identifiers first", fn() {
      // Act
      let found = precedence("1.0.0-alpha", "1.0.0-alpha.1")

      // Assert
      found
      |> should
      |> be_equal(Ok(order.Lt))
      |> or_fail_with("alpha should come before alpha.1")
    }),
    it("finds equal pre-releases equal", fn() {
      // Act
      let found = precedence("1.0.0-rc.1", "1.0.0-rc.1")

      // Assert
      found
      |> should
      |> be_equal(Ok(order.Eq))
      |> or_fail_with("The same pre-release should be equal")
    }),
    it("sorts the example of semver.org section 11", fn() {
      // Arrange
      let texts = [
        "1.0.0", "1.0.0-rc.1", "1.0.0-alpha.beta", "1.0.0-beta.11",
        "1.0.0-alpha", "1.0.0-beta", "1.0.0-alpha.1", "1.0.0-beta.2",
      ]

      // Act
      let sorted =
        list.sort(texts, fn(first, second) {
          precedence(first, second) |> result.unwrap(order.Eq)
        })

      // Assert
      sorted
      |> should
      |> be_equal([
        "1.0.0-alpha", "1.0.0-alpha.1", "1.0.0-alpha.beta", "1.0.0-beta",
        "1.0.0-beta.2", "1.0.0-beta.11", "1.0.0-rc.1", "1.0.0",
      ])
      |> or_fail_with("The order should be the order of semver.org")
    }),
    it("rejects pre-release identifiers that semver does not allow", fn() {
      // Arrange
      let texts = [
        "1.0.0-", "1.0.0-rc..1", "1.0.0-01", "1.0.0-rc_1", "1.0.0-rc.",
      ]

      // Act
      let versions = list.map(texts, check.parse_release_version)

      // Assert
      versions
      |> should
      |> be_equal([Error(Nil), Error(Nil), Error(Nil), Error(Nil), Error(Nil)])
      |> or_fail_with("Each text should not be a version")
    }),
  ])
}

fn one_line_tests() -> UnitNode {
  group("one-line messages", [
    it("shows a line break in a file name in a visible form", fn() {
      // Arrange
      let problem = Problem("docs/a\nb.md", 3, UnclosedFence)

      // Act
      let line = check.describe_problem(problem, project())

      // Assert
      line
      |> should
      |> be_equal("docs/a\\nb.md:3: this code fence has no closing fence")
      |> or_fail_with("The problem should stay on one line")
    }),
    it("shows a carriage return and a tab in a title in a visible form", fn() {
      // Arrange
      let reason =
        ReleaseNotesTitleMismatch(found: "# dream\t3.0.0\r", version: "3.0.0")

      // Act
      let text = check.describe_reason(reason, project())

      // Assert
      text
      |> should
      |> be_equal(
        "the first line is \"# dream\\t3.0.0\\r\", but the template wants the title \"# <Name> 3.0.0 Release Notes\"; see \"Release notes template\" in docs/contributing/release-notes.md",
      )
      |> or_fail_with("The reason should stay on one line")
    }),
  ])
}

fn summary_tests() -> UnitNode {
  group("summary", [
    it("uses the singular for 1", fn() {
      // Act
      let line = check.summary(1, 1, 1, 1)

      // Assert
      line
      |> should
      |> be_equal("1 block and 1 diff block checked in 1 file, 1 problem")
      |> or_fail_with("1 should take the singular")
    }),
    it("uses the plural for 0", fn() {
      // Act
      let line = check.summary(0, 0, 0, 0)

      // Assert
      line
      |> should
      |> be_equal("0 blocks and 0 diff blocks checked in 0 files, 0 problems")
      |> or_fail_with("0 should take the plural")
    }),
  ])
}

fn version_tests() -> UnitNode {
  group("versions", [
    it("reads the identifiers of a pre-release version", fn() {
      // Act
      let version = check.parse_release_version("3.0.0-rc.1")

      // Assert
      version
      |> should
      |> be_equal(
        Ok(
          Version(3, 0, 0, [AlphanumericIdentifier("rc"), NumericIdentifier(1)]),
        ),
      )
      |> or_fail_with("The -rc.1 part should be read")
    }),
    it("rejects a version number with a leading zero", fn() {
      // Act
      let version = check.parse_release_version("3.0.01")

      // Assert
      version
      |> should
      |> be_equal(Error(Nil))
      |> or_fail_with("01 is not a version number")
    }),
    it("compares versions by major, minor and patch", fn() {
      // Act
      let order =
        check.compare_versions(Version(3, 1, 0, []), Version(3, 0, 9, []))

      // Assert
      order
      |> should
      |> be_equal(order.Gt)
      |> or_fail_with("3.1.0 should come after 3.0.9")
    }),
    it("reads the name of a changelog section", fn() {
      // Act
      let name = check.changelog_section_name("## [3.0.0] - 2026-11-20")

      // Assert
      name
      |> should
      |> be_equal(Ok("3.0.0"))
      |> or_fail_with("The name should be the text in the brackets")
    }),
    it(
      "checks Unreleased, later versions and names that are not versions",
      fn() {
        // Arrange
        let names = ["Unreleased", "2.4.1", "3.0.0", "Notes"]

        // Act
        let checked =
          list.map(names, check.is_checked_changelog_section(
            _,
            Version(3, 0, 0, []),
          ))

        // Assert
        checked
        |> should
        |> be_equal([True, False, True, True])
        |> or_fail_with("Only 2.4.1 is before 3.0.0")
      },
    ),
  ])
}

fn fence_tests() -> UnitNode {
  group("fences", [
    it("fails a fence with no closing fence", fn() {
      // Arrange
      let lines = ["```gleam", "x"]

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem("doc.md", 1, UnclosedFence),
        Problem("doc.md", 1, MissingBadgeHeading),
      ])
      |> or_fail_with("An unclosed fence should fail, and its block too")
    }),
    it("passes a tested block in a ~~~ fence", fn() {
      // Arrange
      let lines =
        list.flatten([
          [heading(snippet_path <> "#L7-L9"), "~~~gleam"],
          main_function(),
          ["~~~"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report
      |> should
      |> be_equal(
        Report(blocks_checked: 1, diff_blocks_checked: 0, problems: []),
      )
      |> or_fail_with("A ~~~ fence should be checked like a ``` fence")
    }),
    it("reads the first word of the info string as the language", fn() {
      // Arrange
      let lines =
        list.flatten([
          [heading(snippet_path <> "#L7-L9"), "```Gleam title=main"],
          main_function(),
          ["```"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report
      |> should
      |> be_equal(
        Report(blocks_checked: 1, diff_blocks_checked: 0, problems: []),
      )
      |> or_fail_with("The language should be gleam")
    }),
    it(
      "does not read a line with a backtick in its info string as a fence",
      fn() {
        // Arrange
        let lines = ["```a` b```", "import gleam/io"]

        // Act
        let report = check(lines)

        // Assert
        report
        |> should
        |> be_equal(
          Report(blocks_checked: 0, diff_blocks_checked: 0, problems: []),
        )
        |> or_fail_with("The line is inline code, not a fence")
      },
    ),
    it("removes the indent of an indented fence from its lines", fn() {
      // Arrange
      let lines = [
        heading(snippet_path <> "#L7-L9"),
        "  ```gleam",
        "  pub fn main() {",
        "    io.println(\"hi\")",
        "  }",
        "  ```",
      ]

      // Act
      let report = check(lines)

      // Assert
      report
      |> should
      |> be_equal(
        Report(blocks_checked: 1, diff_blocks_checked: 0, problems: []),
      )
      |> or_fail_with("The fence indent should not count as code")
    }),
    it("fails a block that has only a blank line above it", fn() {
      // Arrange
      let lines = ["", "```gleam", "x", "```"]

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 2, MissingBadgeHeading)])
      |> or_fail_with("A blank line is not a heading")
    }),
    it("fails Gleam code in the prose of a markdown example", fn() {
      // Arrange
      let lines = ["````markdown", "use x <- result.try(y)", "````"]

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 2, HiddenGleamCode("markdown"))])
      |> or_fail_with("Gleam code in an example document should fail")
    }),
    it("tells Gleam lines from the lines of other languages", fn() {
      // Arrange
      let lines = [
        "import gleam/io", "import gleam.{type Int}", "import os",
        "pub fn main() {", "fn x -> x end", "pub type User",
        "type User = { id: number }", "use x <- result.try(y)",
        "let assert Ok(x) = y", "|> list.map(f)", "|> Enum.map(f)",
      ]

      // Act
      let looks = list.map(lines, check.looks_like_gleam)

      // Assert
      looks
      |> should
      |> be_equal([
        True, True, False, True, False, True, False, True, True, True, False,
      ])
      |> or_fail_with("Only the Gleam forms should look like Gleam")
    }),
    it("skips ///// lines, which are not doc comments", fn() {
      // Arrange
      let source = document(["///// ```gleam", "///// x", "///// ```"])

      // Act
      let report = check.check_gleam_source("src/a.gleam", source, context())

      // Assert
      report
      |> should
      |> be_equal(
        Report(blocks_checked: 0, diff_blocks_checked: 0, problems: []),
      )
      |> or_fail_with("A ///// line should not be read as a doc comment")
    }),
  ])
}

fn heading_tests() -> UnitNode {
  group("headings", [
    it("fails the old Tested source line in place of a heading", fn() {
      // Arrange
      let lines = ["<sub>🧪 Tested source</sub>", "```gleam", "x", "```"]

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 1, OldTestedSourceLine)])
      |> or_fail_with("The old line above a block should fail at that line")
    }),
    it("fails a heading that names the badge but has no badge link", fn() {
      // Arrange
      let lines = ["### X <img alt=\"Tested snippet\">", "```gleam", "x", "```"]

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 2, MalformedBadge)])
      |> or_fail_with("A badge with no link should be malformed")
    }),
    it("fails a heading with a badge and no title", fn() {
      // Arrange
      let lines =
        list.flatten([
          [
            "### <a href=\"https://github.com/TrustBound/dream/blob/3.0.0/"
              <> snippet_path
              <> "#L7-L9"
              <> check_context.badge_end,
            "```gleam",
          ],
          main_function(),
          ["```"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 2, MalformedBadge)])
      |> or_fail_with("A heading needs a title before the badge")
    }),
    it("fails a heading with a plain link in place of the badge", fn() {
      // Arrange
      let lines = [
        "### X <a href=\"https://example.com\">docs</a>", "```gleam", "x", "```",
      ]

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 2, MissingBadgeHeading)])
      |> or_fail_with("A plain link is not a badge")
    }),
    it("fails a diff heading that names the badge but has no badge link", fn() {
      // Arrange
      let lines =
        list.flatten([
          ["### Change <img alt=\"Tested diff\">", "```diff"],
          diff_file_header(diff_path),
          ["-  case request.stream {", "```"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 2, MalformedDiffBadge)])
      |> or_fail_with("A diff badge with no link should be malformed")
    }),
    it("fails a diff block under a line that is not a heading", fn() {
      // Arrange
      let lines =
        list.flatten([
          ["Prose.", "```diff"],
          diff_file_header(diff_path),
          ["-  case request.stream {", "```"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 2, MissingDiffBadgeHeading)])
      |> or_fail_with("Prose is not a diff badge heading")
    }),
  ])
}

fn link_tests() -> UnitNode {
  let repository = GitHubRepository(owner: "TrustBound", name: "dream")
  group("links", [
    it("reads the tag, the path and the anchor of a badge link", fn() {
      // Arrange
      let address =
        "https://github.com/TrustBound/dream/blob/3.0.0/test/snippets/example.gleam#L7-L9"

      // Act
      let link = check.parse_snippet_link(address, repository)

      // Assert
      link
      |> should
      |> be_equal(
        Ok(SnippetLink(
          tag: "3.0.0",
          path: "test/snippets/example.gleam",
          anchor: "#L7-L9",
        )),
      )
      |> or_fail_with("The link should be split into its parts")
    }),
    it("rejects a badge link with no path after the tag", fn() {
      // Arrange
      let address = "https://github.com/TrustBound/dream/blob/3.0.0"

      // Act
      let link = check.parse_snippet_link(address, repository)

      // Assert
      link
      |> should
      |> be_equal(Error(ForeignLink(address)))
      |> or_fail_with("A link with no path should fail")
    }),
    it("rejects a badge link out of the repository", fn() {
      // Arrange
      let address =
        "https://github.com/TrustBound/dream/blob/3.0.0/../secret.gleam"

      // Act
      let link = check.parse_snippet_link(address, repository)

      // Assert
      link
      |> should
      |> be_equal(Error(ForeignLink(address)))
      |> or_fail_with("A path with .. should fail")
    }),
    it("reads no anchor as the whole file", fn() {
      // Act
      let selection = check.parse_line_selection("")

      // Assert
      selection
      |> should
      |> be_equal(Ok(WholeFile))
      |> or_fail_with("No anchor should name the whole file")
    }),
    it("rejects anchors that are not line anchors or start at line 0", fn() {
      // Arrange
      let anchors = ["#readme", "#L0"]

      // Act
      let selections = list.map(anchors, check.parse_line_selection)

      // Assert
      selections
      |> should
      |> be_equal([
        Error(MalformedLineRange("#readme")),
        Error(MalformedLineRange("#L0")),
      ])
      |> or_fail_with("#readme and #L0 should be malformed")
    }),
    it("rejects compare links of other forms", fn() {
      // Arrange
      let start = "https://github.com/TrustBound/dream/compare/"
      let addresses = [
        start <> "2.4.1...3.0.0",
        start <> "2.4.1..3.0.0#diff-ab",
        start <> "2.4.1...3.0.0#L1",
        start <> "2.4.1...3.0.0#diff-",
        start <> "-x...3.0.0#diff-ab",
      ]

      // Act
      let links = list.map(addresses, check.parse_compare_link(_, repository))

      // Assert
      links
      |> should
      |> be_equal(
        list.map(addresses, fn(address) { Error(NotCompareLink(address)) }),
      )
      |> or_fail_with("Each address should fail as not a compare link")
    }),
    it("accepts safe tags only", fn() {
      // Arrange
      let tags = ["3.0.0", "v3.0.0-rc_1", "", "-x", "a..b", "a/b"]

      // Act
      let safe = list.map(tags, check.is_safe_tag)

      // Assert
      safe
      |> should
      |> be_equal([True, True, False, False, False, False])
      |> or_fail_with("Only the first two tags are safe")
    }),
    it("accepts safe paths only", fn() {
      // Arrange
      let paths = ["src/a.gleam", "-a.gleam", "a b.gleam", "../a.gleam"]

      // Act
      let safe = list.map(paths, check.is_safe_path)

      // Assert
      safe
      |> should
      |> be_equal([True, False, False, False])
      |> or_fail_with("Only the first path is safe")
    }),
  ])
}

fn snippet_file_tests() -> UnitNode {
  group("snippet files", [
    it("fails a link to a file that cannot be read", fn() {
      // Arrange
      let lines =
        list.flatten([
          [heading(unreadable_path), "```gleam"],
          main_function(),
          ["```"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem(
          "doc.md",
          2,
          UnreadableFile(path: unreadable_path, reason: simplifile.Eacces),
        ),
      ])
      |> or_fail_with("An unreadable file should fail")
    }),
    it("passes a line range of a file with no final newline", fn() {
      // Arrange
      let lines =
        list.flatten([
          [heading(plain_snippet_path <> "#L3-L5"), "```gleam"],
          main_function(),
          ["```"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report
      |> should
      |> be_equal(
        Report(blocks_checked: 1, diff_blocks_checked: 0, problems: []),
      )
      |> or_fail_with("The last line has no newline and should still match")
    }),
    it("fails a whole-file block of a file with no final newline", fn() {
      // Arrange
      let lines =
        list.flatten([
          [heading(plain_snippet_path), "```gleam", "import gleam/io", ""],
          main_function(),
          ["```"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem(
          "doc.md",
          2,
          BlockDiffers(
            path: plain_snippet_path,
            anchor: "",
            first_difference_line: 8,
          ),
        ),
      ])
      |> or_fail_with("A whole file must end with a newline")
    }),
    it(
      "passes a whole-file block that leaves out a module comment with no blank line after it",
      fn() {
        // Arrange
        let lines = [
          heading(tight_snippet_path),
          "```gleam",
          "pub const answer = 42",
          "```",
        ]

        // Act
        let report = check(lines)

        // Assert
        report
        |> should
        |> be_equal(
          Report(blocks_checked: 1, diff_blocks_checked: 0, problems: []),
        )
        |> or_fail_with("The module comment alone should be left out")
      },
    ),
    it("fails an empty whole-file block", fn() {
      // Arrange
      let lines = [heading(snippet_path), "```gleam", "```"]

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem(
          "doc.md",
          2,
          BlockDiffers(path: snippet_path, anchor: "", first_difference_line: 3),
        ),
      ])
      |> or_fail_with("An empty block should differ at its closing fence")
    }),
  ])
}

fn more_diff_tests() -> UnitNode {
  group("diff blocks", [
    it("fails a diff block with one line", fn() {
      // Act
      let report = diff_report(["-a"])

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 3, MissingDiffFileHeader)])
      |> or_fail_with("One line cannot hold a file header")
    }),
    it("fails a line that is not in the hunk of its header", fn() {
      // Arrange
      let body =
        list.append(diff_file_header(diff_path), [
          "@@ -1,4 +1,4 @@",
          "-not a real line",
        ])

      // Act
      let report = diff_report(body)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem(
          "doc.md",
          7,
          DiffLineNotFound(
            path: diff_path,
            old_tag: "2.4.1",
            new_side: WorkingTree,
          ),
        ),
      ])
      |> or_fail_with("The made-up line should fail at its line")
    }),
    it("fails a hunk header that matches no header of an odd diff", fn() {
      // Arrange
      let body =
        list.append(diff_file_header(odd_diff_path), ["@@ other", "-old line"])

      // Act
      let report =
        check(diff_document(diff_heading("2.4.1...3.0.0", odd_diff_path), body))

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 6, HunkHeaderNotFound("@@ other"))])
      |> or_fail_with("@@ other is not a header of the diff")
    }),
    it("passes a line of a diff with no final newline", fn() {
      // Arrange
      let body = list.append(diff_file_header(odd_diff_path), ["-old line"])

      // Act
      let report =
        check(diff_document(diff_heading("2.4.1...3.0.0", odd_diff_path), body))

      // Assert
      report
      |> should
      |> be_equal(
        Report(blocks_checked: 0, diff_blocks_checked: 1, problems: []),
      )
      |> or_fail_with("The last line of the diff should be found")
    }),
    it("fails when git cannot read the diff", fn() {
      // Arrange
      let failing_diff =
        CheckContext(..context(), diff_from_tag: fn(_tag, _path) {
          Error(GitFailed(status: 128, output: ""))
        })
      let lines =
        diff_document(
          diff_heading("2.4.1...3.0.0", diff_path),
          list.append(diff_file_header(diff_path), ["-  case request.stream {"]),
        )

      // Act
      let report = check.check_markdown("doc.md", document(lines), failing_diff)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem("doc.md", 3, GitUnavailable(GitFailed(status: 128, output: ""))),
      ])
      |> or_fail_with("A git failure should be a problem")
    }),
    it("splits a diff into hunks", fn() {
      // Act
      let hunks = check.parse_hunks(odd_diff)

      // Assert
      hunks
      |> should
      |> be_equal([DiffHunk(header: "@@ odd", lines: ["-old line"])])
      |> or_fail_with("The diff should have one hunk with one line")
    }),
  ])
}

fn describe_tests() -> UnitNode {
  let other_project =
    Project(
      name: "my_app",
      version: "1.2.0",
      repository: GitHubRepository(owner: "me", name: "my_app"),
      badge_guide: "CONTRIBUTING.md",
      release_notes_guide: "RELEASING.md",
      guides: ["docs/guides"],
    )
  group("describe_reason", [
    it("describes every reason of a snippet block", fn() {
      // Arrange
      let reasons = [
        MissingBadgeHeading,
        OldTestedSourceLine,
        MalformedBadge,
        ForeignLink("https://example.com/a.gleam"),
        MissingFile("test/snippets/missing.gleam"),
        UnreadableFile(path: unreadable_path, reason: simplifile.Eacces),
        MalformedLineRange("#L7-9"),
        ReversedLineRange(start: 9, end: 7),
        LineRangePastEnd(end: 11, line_count: 9),
        BlockDiffers(
          path: snippet_path,
          anchor: "#L7-L9",
          first_difference_line: 4,
        ),
        HiddenGleamCode(""),
        HiddenGleamCode("text"),
        UnclosedFence,
      ]

      // Act
      let descriptions = list.map(reasons, check.describe_reason(_, project()))

      // Assert
      descriptions
      |> should
      |> be_equal([
        "this gleam code block has no heading with the tested snippet badge directly above it (one blank line between is allowed)",
        "the old \"🧪 Tested source\" line is not used now; put the tested snippet badge at the end of the heading above the code block",
        "the tested snippet badge is not in the exact format; copy it from docs/contributing/contributing.md",
        "the badge link https://example.com/a.gleam does not point at a file in https://github.com/TrustBound/dream",
        "the badge links to test/snippets/missing.gleam, which is not a file in this repository",
        "cannot read test/snippets/locked.gleam: Permission denied",
        "the line anchor #L7-9 is not #L<n> or #L<start>-L<end>",
        "the line range starts at line 9, after its end at line 7",
        "the line range ends at line 11, but the file has 9 lines",
        "the code block is not the same as test/snippets/example.gleam#L7-L9; the first difference is at line 4",
        "this line looks like Gleam code in a code fence with no language; put Gleam code in a gleam block with the tested snippet badge",
        "this line looks like Gleam code in a text code fence; put Gleam code in a gleam block with the tested snippet badge",
        "this code fence has no closing fence",
      ])
      |> or_fail_with("Each snippet reason should have dream's message")
    }),
    it("describes every reason of a diff block", fn() {
      // Arrange
      let reasons = [
        MissingDiffBadgeHeading,
        MalformedDiffBadge,
        NotCompareLink("https://example.com"),
        WrongNewTag(found: "2.9.0", expected: "3.0.0"),
        MissingDiffFileHeader,
        EmptyDiffBlock,
        WrongDiffAnchor(path: diff_path, expected: "#diff-abc"),
        MissingOldTag("1.9.9"),
        GitUnavailable(GitNotFound),
        GitUnavailable(GitFailed(status: 128, output: "")),
        NoDiffForPath(
          path: "src/same.gleam",
          old_tag: "2.4.1",
          new_side: WorkingTree,
        ),
        HunkHeaderNotFound("@@ -1 +1 @@"),
        DiffLineNotFound(
          path: diff_path,
          old_tag: "2.4.1",
          new_side: WorkingTree,
        ),
      ]

      // Act
      let descriptions = list.map(reasons, check.describe_reason(_, project()))

      // Assert
      descriptions
      |> should
      |> be_equal([
        "this diff block has no heading with the tested diff badge directly above it (one blank line between is allowed)",
        "the tested diff badge is not in the exact format; copy it from docs/contributing/contributing.md",
        "the diff badge link https://example.com is not https://github.com/TrustBound/dream/compare/<old tag>...<new tag>#diff-<digest>",
        "the compare link ends at the tag 2.9.0, but this file must use the new tag 3.0.0 (the docs of dream use the version in gleam.toml)",
        "the diff block does not start with \"--- a/<path>\" and \"+++ b/<path>\" for one path of letters, digits and . _ - /",
        "the diff block has no diff lines after its file header",
        "the compare link anchor is not the one for src/app.gleam; use #diff-abc",
        "the tag 1.9.9 is not in this clone; fetch the tags with \"git fetch --tags\" (a shallow clone has none)",
        "cannot run git: git is not on the PATH",
        "cannot run git: git stopped with exit status 128",
        "src/same.gleam has no changes since the tag 2.4.1",
        "the hunk header @@ -1 +1 @@ is not a hunk header of the real diff, or it is out of order",
        "this line is not in \"git diff 2.4.1 -- src/app.gleam\" at this place; a diff block shows lines of the real diff, in order and contiguous within a hunk",
      ])
      |> or_fail_with("Each diff reason should have dream's message")
    }),
    it(
      "names the repository, the package and the guide of another project",
      fn() {
        // Arrange
        let reasons = [
          ForeignLink("https://example.com/a.gleam"),
          WrongTag(found: "1.0.0", expected: "1.2.0"),
          MalformedBadge,
          NotCompareLink("https://example.com"),
        ]

        // Act
        let descriptions =
          list.map(reasons, check.describe_reason(_, other_project))

        // Assert
        descriptions
        |> should
        |> be_equal([
          "the badge link https://example.com/a.gleam does not point at a file in https://github.com/me/my_app",
          "the badge link uses the tag 1.0.0, but this file must link at the tag 1.2.0 (the docs of my_app use the version in gleam.toml)",
          "the tested snippet badge is not in the exact format; copy it from CONTRIBUTING.md",
          "the diff badge link https://example.com is not https://github.com/me/my_app/compare/<old tag>...<new tag>#diff-<digest>",
        ])
        |> or_fail_with("The messages should come from the project")
      },
    ),
    it("builds the address of a GitHub repository", fn() {
      // Arrange
      let repository =
        GitHubRepository(owner: "TrustBound", name: "dream_snippets")

      // Act
      let url = check.repository_url(repository)

      // Assert
      url
      |> should
      |> be_equal("https://github.com/TrustBound/dream_snippets")
      |> or_fail_with("The address should name the owner and the repository")
    }),
  ])
}

fn passing_tests() -> UnitNode {
  group("passes", [
    it("a whole-file block with its module comment", fn() {
      // Arrange
      let lines =
        list.flatten([
          [heading(snippet_path), "", "```gleam"],
          string.split(string.drop_end(snippet_source, 1), "\n"),
          ["```"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report
      |> should
      |> be_equal(
        Report(blocks_checked: 1, diff_blocks_checked: 0, problems: []),
      )
      |> or_fail_with("A whole-file block should pass")
    }),
    it("a whole-file block that leaves out the module comment", fn() {
      // Arrange
      let lines =
        list.flatten([
          [heading(snippet_path), "", "```gleam"],
          ["import gleam/io", "", "pub const answer = 42", ""],
          main_function(),
          ["```"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report
      |> should
      |> be_equal(
        Report(blocks_checked: 1, diff_blocks_checked: 0, problems: []),
      )
      |> or_fail_with("A block without the module comment should pass")
    }),
    it("a line-range block", fn() {
      // Arrange
      let lines =
        list.flatten([
          [heading(snippet_path <> "#L7-L9"), "", "```gleam"],
          main_function(),
          ["```"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report
      |> should
      |> be_equal(
        Report(blocks_checked: 1, diff_blocks_checked: 0, problems: []),
      )
      |> or_fail_with("A #L7-L9 block should pass")
    }),
    it("a single-line block with its indent", fn() {
      // Arrange
      let lines = [
        heading(snippet_path <> "#L8"),
        "```gleam",
        "  io.println(\"hi\")",
        "```",
      ]

      // Act
      let report = check(lines)

      // Assert
      report
      |> should
      |> be_equal(
        Report(blocks_checked: 1, diff_blocks_checked: 0, problems: []),
      )
      |> or_fail_with("A #L8 block should pass")
    }),
    it("a block in a /// doc comment", fn() {
      // Arrange
      let source =
        document([
          "/// Runs the example.",
          "///",
          "/// " <> heading(snippet_path <> "#L7-L9"),
          "///",
          "/// ```gleam",
          "/// pub fn main() {",
          "///   io.println(\"hi\")",
          "/// }",
          "/// ```",
          "pub fn run() {",
          "  Nil",
          "}",
        ])

      // Act
      let report = check.check_gleam_source("src/a.gleam", source, context())

      // Assert
      report
      |> should
      |> be_equal(
        Report(blocks_checked: 1, diff_blocks_checked: 0, problems: []),
      )
      |> or_fail_with("A /// doc comment block should pass")
    }),
    it("a block in a //// module comment", fn() {
      // Arrange
      let source =
        document([
          "//// " <> heading(snippet_path <> "#L5"),
          "////",
          "//// ```gleam",
          "//// pub const answer = 42",
          "//// ```",
          "",
          "pub const zero = 0",
        ])

      // Act
      let report = check.check_gleam_source("src/a.gleam", source, context())

      // Assert
      report
      |> should
      |> be_equal(
        Report(blocks_checked: 1, diff_blocks_checked: 0, problems: []),
      )
      |> or_fail_with("A //// module comment block should pass")
    }),
    it("a block in an indented doc comment", fn() {
      // Arrange
      let source =
        document([
          "pub type Example {",
          "  /// " <> heading(snippet_path <> "#L7-L9"),
          "  ///",
          "  /// ```gleam",
          "  /// pub fn main() {",
          "  ///   io.println(\"hi\")",
          "  /// }",
          "  /// ```",
          "  Example",
          "}",
        ])

      // Act
      let report = check.check_gleam_source("src/a.gleam", source, context())

      // Assert
      report
      |> should
      |> be_equal(
        Report(blocks_checked: 1, diff_blocks_checked: 0, problems: []),
      )
      |> or_fail_with("An indented doc comment block should pass")
    }),
    it("a gleam block inside a ````markdown example", fn() {
      // Arrange
      let lines =
        list.flatten([
          ["````markdown", "Some prose.", "", heading(snippet_path <> "#L7-L9")],
          ["", "```gleam"],
          main_function(),
          ["```", "````"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report
      |> should
      |> be_equal(
        Report(blocks_checked: 1, diff_blocks_checked: 0, problems: []),
      )
      |> or_fail_with("A tested block inside a markdown example should pass")
    }),
    it("shell, JavaScript, Elixir and TOML fences", fn() {
      // Arrange
      let lines = [
        "```bash", "gleam run -m dream_snippets", "make check | tee log", "```",
        "```javascript", "import { x } from \"./a/b.js\";", "let total = 1;",
        "```", "```elixir", "Enum.map(list, fn x -> x end)", "|> Enum.sum()",
        "```", "```toml", "[dependencies]", "dream = \">= 3.0.0\"", "```", "```",
        "type User = { id: number }", "```",
      ]

      // Act
      let report = check(lines)

      // Assert
      report
      |> should
      |> be_equal(
        Report(blocks_checked: 0, diff_blocks_checked: 0, problems: []),
      )
      |> or_fail_with("Fences in other languages should pass")
    }),
  ])
}

fn failing_tests() -> UnitNode {
  group("fails", [
    it("a gleam block with no heading above", fn() {
      // Arrange
      let lines =
        list.flatten([["Some prose.", "", "```gleam"], main_function(), ["```"]])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 3, MissingBadgeHeading)])
      |> or_fail_with("A block with no heading should fail")
    }),
    it("a heading with two blank lines before the block", fn() {
      // Arrange
      let lines =
        list.flatten([
          [heading(snippet_path <> "#L7-L9"), "", "", "```gleam"],
          main_function(),
          ["```"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 4, MissingBadgeHeading)])
      |> or_fail_with("Only one blank line is allowed")
    }),
    it("a badge that is not in the exact format", fn() {
      // Arrange
      let malformed =
        string.replace(
          heading(snippet_path <> "#L7-L9"),
          "alt=\"Tested snippet\"",
          "alt=\"Tested Snippet\"",
        )
      let lines =
        list.flatten([[malformed, "```gleam"], main_function(), ["```"]])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 2, MalformedBadge)])
      |> or_fail_with("A badge with other alt text should fail")
    }),
    it("a badge that links to another repository", fn() {
      // Arrange
      let url =
        "https://github.com/someone/dream/blob/3.0.0/test/snippets/example.gleam"
      let lines =
        list.flatten([
          [
            "### Example <a href=\"" <> url <> check_context.badge_end,
            "```gleam",
          ],
          main_function(),
          ["```"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 2, ForeignLink(url))])
      |> or_fail_with("A link to another repository should fail")
    }),
    it("a badge with a tag that is not the gleam.toml version", fn() {
      // Arrange
      let old_tag =
        string.replace(heading(snippet_path <> "#L7-L9"), "/3.0.0/", "/2.5.0/")
      let lines =
        list.flatten([[old_tag, "```gleam"], main_function(), ["```"]])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem("doc.md", 2, WrongTag(found: "2.5.0", expected: "3.0.0")),
      ])
      |> or_fail_with("A link at tag 2.5.0 should fail")
    }),
    it("a badge that links to a file that does not exist", fn() {
      // Arrange
      let lines =
        list.flatten([
          [heading("test/snippets/missing.gleam"), "```gleam"],
          main_function(),
          ["```"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem("doc.md", 2, MissingFile("test/snippets/missing.gleam")),
      ])
      |> or_fail_with("A link to a missing file should fail")
    }),
    it("a malformed line range", fn() {
      // Arrange
      let lines =
        list.flatten([
          [heading(snippet_path <> "#L7-9"), "```gleam"],
          main_function(),
          ["```"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 2, MalformedLineRange("#L7-9"))])
      |> or_fail_with("#L7-9 should fail")
    }),
    it("a reversed line range", fn() {
      // Arrange
      let lines =
        list.flatten([
          [heading(snippet_path <> "#L9-L7"), "```gleam"],
          main_function(),
          ["```"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 2, ReversedLineRange(start: 9, end: 7))])
      |> or_fail_with("#L9-L7 should fail")
    }),
    it("a line range past the end of the file", fn() {
      // Arrange
      let lines =
        list.flatten([
          [heading(snippet_path <> "#L7-L11"), "```gleam"],
          main_function(),
          ["```"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem("doc.md", 2, LineRangePastEnd(end: 11, line_count: 9)),
      ])
      |> or_fail_with("#L7-L11 of a 9-line file should fail")
    }),
    it("a block that differs from its line range", fn() {
      // Arrange
      let lines = [
        heading(snippet_path <> "#L7-L9"),
        "```gleam",
        "pub fn main() {",
        "  io.println(\"ho\")",
        "}",
        "```",
      ]

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem(
          "doc.md",
          2,
          BlockDiffers(
            path: snippet_path,
            anchor: "#L7-L9",
            first_difference_line: 4,
          ),
        ),
      ])
      |> or_fail_with("A changed character should fail")
    }),
    it("a block with a changed indent", fn() {
      // Arrange
      let lines = [
        heading(snippet_path <> "#L8"),
        "```gleam",
        "io.println(\"hi\")",
        "```",
      ]

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem(
          "doc.md",
          2,
          BlockDiffers(
            path: snippet_path,
            anchor: "#L8",
            first_difference_line: 3,
          ),
        ),
      ])
      |> or_fail_with("A block with no indent should fail")
    }),
    it("a whole-file block that misses the last line", fn() {
      // Arrange
      let lines =
        list.flatten([
          [heading(snippet_path), "```gleam"],
          ["import gleam/io", "", "pub const answer = 42", ""],
          ["pub fn main() {", "  io.println(\"hi\")"],
          ["```"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem(
          "doc.md",
          2,
          BlockDiffers(path: snippet_path, anchor: "", first_difference_line: 9),
        ),
      ])
      |> or_fail_with("A whole-file block with a missing line should fail")
    }),
    it("a block with the old Tested source line", fn() {
      // Arrange
      let lines =
        list.flatten([
          ["## Example", "", "Prose.", "", "```gleam"],
          main_function(),
          ["```", "<sub>🧪 [Tested source](test/snippets/example.gleam)</sub>"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem("doc.md", 5, MissingBadgeHeading),
        Problem("doc.md", 10, OldTestedSourceLine),
      ])
      |> or_fail_with("The old Tested source form should fail")
    }),
    it("Gleam code in a text fence", fn() {
      // Arrange
      let lines =
        list.flatten([["Prose.", "", "```text"], main_function(), ["```"]])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 4, HiddenGleamCode("text"))])
      |> or_fail_with("Gleam code in a text fence should fail")
    }),
    it("Gleam code in a fence with no language", fn() {
      // Arrange
      let lines = ["```", "import dream/http.{type Request}", "```"]

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 2, HiddenGleamCode(""))])
      |> or_fail_with("Gleam code in a bare fence should fail")
    }),
    it("an untested gleam block inside a ````markdown example", fn() {
      // Arrange
      let lines =
        list.flatten([
          ["````markdown", "## Example", "", "```gleam"],
          main_function(),
          ["```", "````"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 4, MissingBadgeHeading)])
      |> or_fail_with("A block inside a markdown example should be checked")
    }),
  ])
}

fn report_tests() -> UnitNode {
  group("reports", [
    it("every problem in every file, sorted by file and line", fn() {
      // Arrange
      let second =
        check(
          list.flatten([
            ["```text", "use x <- result.try(y)", "```", "```gleam"],
            main_function(),
            ["```"],
          ]),
        )
      let first =
        check.check_markdown(
          "a.md",
          document(["```gleam", "x", "```", "```gleam", "y", "```"]),
          context(),
        )
      let problems = list.append(second.problems, first.problems)

      // Act
      let sorted = check.sort_problems(problems)

      // Assert
      sorted
      |> should
      |> be_equal([
        Problem("a.md", 1, MissingBadgeHeading),
        Problem("a.md", 4, MissingBadgeHeading),
        Problem("doc.md", 2, HiddenGleamCode("text")),
        Problem("doc.md", 4, MissingBadgeHeading),
      ])
      |> or_fail_with("All problems should be reported, sorted")
    }),
    it("describes a problem as file:line: reason", fn() {
      // Arrange
      let problem =
        Problem("docs/a.md", 12, WrongTag(found: "2.5.0", expected: "3.0.0"))

      // Act
      let line = check.describe_problem(problem, project())

      // Assert
      line
      |> should
      |> be_equal(
        "docs/a.md:12: the badge link uses the tag 2.5.0, but this file must link at the tag 3.0.0 (the docs of dream use the version in gleam.toml)",
      )
      |> or_fail_with("The problem line should name file, line and reason")
    }),
    it("writes the summary line", fn() {
      // Arrange
      let blocks = 509

      // Act
      let line = check.summary(blocks, 5, 84, 2)

      // Assert
      line
      |> should
      |> be_equal(
        "509 blocks and 5 diff blocks checked in 84 files, 2 problems",
      )
      |> or_fail_with("The summary should count blocks, files and problems")
    }),
  ])
}

fn diff_passing_tests() -> UnitNode {
  group("passes a diff block", [
    it("with no hunk header, as a run of lines inside one hunk", fn() {
      // Arrange
      let body =
        list.append(diff_file_header(diff_path), [
          "-  case request.stream {",
          "-    Some(chunks) -> save(chunks)",
          "+  case request.body {",
        ])

      // Act
      let report = diff_report(body)

      // Assert
      report
      |> should
      |> be_equal(
        Report(blocks_checked: 0, diff_blocks_checked: 1, problems: []),
      )
      |> or_fail_with("Real diff lines with no hunk header should pass")
    }),
    it("with hunk headers, one per hunk, in order", fn() {
      // Arrange
      let body =
        list.append(diff_file_header(diff_path), [
          "@@ -1,4 +1,4 @@",
          " import gleam/io",
          "-import gleam/option.{None, Some}",
          "@@ -10,5 +10,5 @@",
          "+    Stream(chunks) -> save(chunks)",
          "   }",
        ])

      // Act
      let report = diff_report(body)

      // Assert
      report
      |> should
      |> be_equal(
        Report(blocks_checked: 0, diff_blocks_checked: 1, problems: []),
      )
      |> or_fail_with(
        "Two hunks with their headers should pass, and the Gleam context line should not count as hidden Gleam code",
      )
    }),
    it("with a hunk header that keeps the function name git adds", fn() {
      // Arrange
      let body =
        list.append(diff_file_header(diff_path), [
          "@@ -10,5 +10,5 @@ pub fn upload(",
          " pub fn upload(request) {",
          "-  case request.stream {",
        ])

      // Act
      let report = diff_report(body)

      // Assert
      report
      |> should
      |> be_equal(
        Report(blocks_checked: 0, diff_blocks_checked: 1, problems: []),
      )
      |> or_fail_with("The full hunk header line should pass")
    }),
  ])
}

fn diff_failing_tests() -> UnitNode {
  let real_lines = ["-  case request.stream {"]
  group("fails a diff block", [
    it("with no heading", fn() {
      // Arrange
      let lines =
        list.flatten([
          ["```diff"],
          diff_file_header(diff_path),
          real_lines,
          ["```"],
        ])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 1, MissingDiffBadgeHeading)])
      |> or_fail_with("A diff block with no badge should fail")
    }),
    it("with a badge that is not in the exact format", fn() {
      // Arrange
      let heading_line =
        string.replace(
          diff_heading("2.4.1...3.0.0", diff_path),
          "flat-square",
          "flat",
        )

      // Act
      let report =
        check(diff_document(
          heading_line,
          list.append(diff_file_header(diff_path), real_lines),
        ))

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 3, MalformedDiffBadge)])
      |> or_fail_with("A changed diff badge should fail")
    }),
    it("with a link that is not a compare link in this repository", fn() {
      // Arrange
      let heading_line =
        string.replace(
          diff_heading("2.4.1...3.0.0", diff_path),
          "TrustBound/dream/compare",
          "someone/dream/compare",
        )
      let address =
        "https://github.com/someone/dream/compare/2.4.1...3.0.0#diff-"
        <> check.path_digest(diff_path)

      // Act
      let report =
        check(diff_document(
          heading_line,
          list.append(diff_file_header(diff_path), real_lines),
        ))

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 3, NotCompareLink(address))])
      |> or_fail_with("A compare link to another repository should fail")
    }),
    it("with a new tag that is not the gleam.toml version", fn() {
      // Arrange
      let heading_line = diff_heading("2.4.1...2.9.0", diff_path)

      // Act
      let report =
        check(diff_document(
          heading_line,
          list.append(diff_file_header(diff_path), real_lines),
        ))

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem("doc.md", 3, WrongNewTag(found: "2.9.0", expected: "3.0.0")),
      ])
      |> or_fail_with("A new tag other than 3.0.0 should fail")
    }),
    it("with an old tag that is not in the clone", fn() {
      // Arrange
      let heading_line = diff_heading("1.9.9...3.0.0", diff_path)

      // Act
      let report =
        check(diff_document(
          heading_line,
          list.append(diff_file_header(diff_path), real_lines),
        ))

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 3, MissingOldTag("1.9.9"))])
      |> or_fail_with("A missing old tag should fail")
    }),
    it("with an anchor that is not the digest of its path", fn() {
      // Arrange
      let heading_line = diff_heading("2.4.1...3.0.0", "src/other.gleam")
      let expected = "#diff-" <> check.path_digest(diff_path)

      // Act
      let report =
        check(diff_document(
          heading_line,
          list.append(diff_file_header(diff_path), real_lines),
        ))

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem("doc.md", 3, WrongDiffAnchor(path: diff_path, expected:)),
      ])
      |> or_fail_with("An anchor for another path should fail")
    }),
    it("with no --- and +++ file header", fn() {
      // Arrange
      let body = ["-import gleam/option.{None, Some}", "+import gleam/string"]

      // Act
      let problems = diff_report(body).problems

      // Assert
      problems
      |> should
      |> be_equal([Problem("doc.md", 3, MissingDiffFileHeader)])
      |> or_fail_with("A block with no file header should fail")
    }),
    it("with a path that has characters git must not get", fn() {
      // Arrange
      let path = "src/$(touch x).gleam"
      let heading_line = diff_heading("2.4.1...3.0.0", path)

      // Act
      let report =
        check(diff_document(
          heading_line,
          list.append(diff_file_header(path), real_lines),
        ))

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 3, MissingDiffFileHeader)])
      |> or_fail_with("An unsafe path should fail before git runs")
    }),
    it("with a file header and no diff lines", fn() {
      // Arrange
      let body = diff_file_header(diff_path)

      // Act
      let problems = diff_report(body).problems

      // Assert
      problems
      |> should
      |> be_equal([Problem("doc.md", 3, EmptyDiffBlock)])
      |> or_fail_with("A block with only a file header should fail")
    }),
    it("for a file with no diff since the old tag", fn() {
      // Arrange
      let path = "src/same.gleam"
      let heading_line = diff_heading("2.4.1...3.0.0", path)

      // Act
      let report =
        check(diff_document(
          heading_line,
          list.append(diff_file_header(path), real_lines),
        ))

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem(
          "doc.md",
          3,
          NoDiffForPath(path:, old_tag: "2.4.1", new_side: WorkingTree),
        ),
      ])
      |> or_fail_with("A file with no changes should fail")
    }),
    it("with a line that is not in the real diff", fn() {
      // Arrange
      let body =
        list.append(diff_file_header(diff_path), [
          "-  case request.stream {",
          "-    Some(chunks) -> keep(chunks)",
        ])

      // Act
      let problems = diff_report(body).problems

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(
          "doc.md",
          7,
          DiffLineNotFound(
            path: diff_path,
            old_tag: "2.4.1",
            new_side: WorkingTree,
          ),
        ),
      ])
      |> or_fail_with("A made-up line should fail at that line")
    }),
    it("with lines from two hunks and no header between them", fn() {
      // Arrange
      let body =
        list.append(diff_file_header(diff_path), [
          " import gleam/yielder",
          " pub fn upload(request) {",
        ])

      // Act
      let problems = diff_report(body).problems

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(
          "doc.md",
          7,
          DiffLineNotFound(
            path: diff_path,
            old_tag: "2.4.1",
            new_side: WorkingTree,
          ),
        ),
      ])
      |> or_fail_with("Lines that are not contiguous in one hunk should fail")
    }),
    it("with a hunk header that is not in the real diff", fn() {
      // Arrange
      let body =
        list.append(diff_file_header(diff_path), [
          "@@ -10,6 +10,5 @@",
          "-  case request.stream {",
        ])

      // Act
      let problems = diff_report(body).problems

      // Assert
      problems
      |> should
      |> be_equal([
        Problem("doc.md", 6, HunkHeaderNotFound("@@ -10,6 +10,5 @@")),
      ])
      |> or_fail_with("A wrong hunk header should fail")
    }),
    it("when git cannot run", fn() {
      // Arrange
      let no_git =
        CheckContext(
          ..context(),
          tag_exists: fn(_tag) { Error(GitNotFound) },
          diff_from_tag: fn(_tag, _path) { Error(GitNotFound) },
        )
      let lines =
        diff_document(
          diff_heading("2.4.1...3.0.0", diff_path),
          list.append(diff_file_header(diff_path), real_lines),
        )

      // Act
      let report = check.check_markdown("doc.md", document(lines), no_git)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 3, GitUnavailable(GitNotFound))])
      |> or_fail_with("A missing git should be a problem, not a crash")
    }),
  ])
}

fn scope_tests() -> UnitNode {
  group("scope", [
    it("reads the version from a release notes file name", fn() {
      // Arrange
      let path = "releases/release-2.4.1.md"

      // Act
      let version = check.release_notes_version(path)

      // Assert
      version
      |> should
      |> be_equal(Ok(Version(2, 4, 1, [])))
      |> or_fail_with("The version should come from the file name")
    }),
    it("skips release notes before 3.0.0", fn() {
      // Arrange
      let paths = [
        "releases/release-2.4.1.md", "releases/release-0.1.0.md",
        "releases/notes.md",
      ]

      // Act
      let checked =
        list.map(paths, check.is_checked_release_notes(_, Version(3, 0, 0, [])))

      // Assert
      checked
      |> should
      |> be_equal([False, False, False])
      |> or_fail_with("Older or unversioned release notes should be skipped")
    }),
    it("checks release notes at and after 3.0.0, compared as numbers", fn() {
      // Arrange
      let paths = [
        "releases/release-3.0.0.md", "releases/release-3.1.0.md",
        "releases/release-10.0.0.md",
      ]

      // Act
      let checked =
        list.map(paths, check.is_checked_release_notes(_, Version(3, 0, 0, [])))

      // Assert
      checked
      |> should
      |> be_equal([True, True, True])
      |> or_fail_with("Release notes from 3.0.0 on should be checked")
    }),
    it("checks only the changelog sections from 3.0.0 on", fn() {
      // Arrange
      let untested_block = ["```gleam", "x", "```"]
      let text =
        document(
          list.flatten([
            ["# Changelog", "", "## [Unreleased]"],
            untested_block,
            ["## [3.0.0] - Unreleased"],
            untested_block,
            ["## [2.4.1] - 2026-03-11"],
            untested_block,
            ["## [1.0.0] - 2025-11-21"],
            untested_block,
          ]),
        )

      // Act
      let report = check.check_changelog("CHANGELOG.md", text, context())

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem("CHANGELOG.md", 4, MissingBadgeHeading),
        Problem("CHANGELOG.md", 8, MissingBadgeHeading),
      ])
      |> or_fail_with("Only [Unreleased] and [3.0.0] should be checked")
    }),
  ])
}

fn digest_tests() -> UnitNode {
  group("path_digest", [
    it("uses the anchor GitHub gives CHANGELOG.md in a compare view", fn() {
      // Arrange
      let path = "CHANGELOG.md"

      // Act
      let digest = check.path_digest(path)

      // Assert
      digest
      |> should
      |> be_equal(
        "06572a96a58dc510037d5efa622f9bec8519bc1beab13c9f251e97e657a9d4ed",
      )
      |> or_fail_with("The anchor should be the SHA-256 digest of the path")
    }),
  ])
}
