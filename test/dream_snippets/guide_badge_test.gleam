//// Tests for the guide badge of README examples, and for the anchors of
//// guide headings.
////
//// Each fixture is a small inline document. The guides and the snippet
//// files are held in `fixtures/check_context`, so the tests never read
//// real files.

import dream_snippets/check.{
  BrokenGuideBadge, ExampleHeading, ExampleNotInGuide, ForeignGuideLink,
  GuideAnchorNotFound, GuideBadgeLink, GuideBadgeNotAllowed, GuideLink,
  MalformedGuideBadge, MissingBadgeHeading, MissingGuideAnchor,
  MissingGuideBadge, MissingGuideFile, NoGuideBadge, NotAGuidePath, Problem,
  Report, UnreadableFile, WrongGuideTag, WrongTag,
}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{type UnitNode, describe, group, it}
import fixtures/check_context.{
  check, check_readme, context, diff_document, diff_file_header, diff_heading,
  diff_path, document, guide_badge_end, guide_path, heading, other_guide_path,
  project, readme_document, readme_heading, snippet_path, unreadable_guide_path,
}
import gleam/list
import gleam/string
import simplifile

const example_target = "test/snippets/example.gleam#L7-L9"

const guide_target = "docs/guides/example.md#example-"

pub fn tests() -> TestSuite {
  describe("dream_snippets/check guide badge", [
    readme_passing_tests(),
    readme_badge_tests(),
    readme_link_tests(),
    other_document_tests(),
    parse_tests(),
    anchor_tests(),
    describe_tests(),
  ])
}

fn readme_passing_tests() -> UnitNode {
  group("check_readme passes", [
    it("an example with both badges", fn() {
      // Arrange
      let lines = readme_document(readme_heading(example_target, guide_target))

      // Act
      let report = check_readme(lines)

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
      |> or_fail_with("The example should pass")
    }),
    it("a guide link with a percent-encoded anchor", fn() {
      // Arrange
      let lines =
        readme_document(readme_heading(
          example_target,
          guide_path <> "#caf%C3%A9-au-lait",
        ))

      // Act
      let report = check_readme(lines)

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
      |> or_fail_with("The anchor should be decoded before it is compared")
    }),
    it("a diff block with only the tested diff badge", fn() {
      // Arrange
      let lines =
        diff_document(
          diff_heading("2.4.1...3.0.0", diff_path),
          list.append(diff_file_header(diff_path), [" import gleam/io"]),
        )

      // Act
      let report = check_readme(lines)

      // Assert
      report
      |> should
      |> be_equal(
        Report(
          ..check.empty_report(),
          blocks_checked: 0,
          diff_blocks_checked: 1,
          problems: [],
        ),
      )
      |> or_fail_with("A diff block heading takes no guide badge")
    }),
  ])
}

fn readme_badge_tests() -> UnitNode {
  group("check_readme guide badge", [
    it("fails an example with no guide badge", fn() {
      // Arrange
      let lines = readme_document(heading(example_target))

      // Act
      let report = check_readme(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("README.md", 1, MissingGuideBadge)])
      |> or_fail_with("The guide badge is required in the README")
    }),
    it("fails a guide badge before the tested snippet badge", fn() {
      // Arrange
      let guide_badge =
        "<a href=\"https://github.com/TrustBound/dream/blob/3.0.0/"
        <> guide_target
        <> guide_badge_end
      let line =
        string.replace(
          heading(example_target),
          "### Example <a href=",
          "### Example " <> guide_badge <> " <a href=",
        )
      let lines = readme_document(line)

      // Act
      let report = check_readme(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("README.md", 1, MalformedGuideBadge)])
      |> or_fail_with("The guide badge must come after the snippet badge")
    }),
    it("fails a guide badge with another image", fn() {
      // Arrange
      let line =
        readme_heading(example_target, guide_target)
        |> string.replace("blue.svg", "green.svg")
      let lines = readme_document(line)

      // Act
      let report = check_readme(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("README.md", 1, MalformedGuideBadge)])
      |> or_fail_with("The image must be the exact guide badge")
    }),
    it("fails a guide badge with an empty link address", fn() {
      // Arrange
      let line = heading(example_target) <> " <a href=\"" <> guide_badge_end
      let lines = readme_document(line)

      // Act
      let report = check_readme(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("README.md", 1, MalformedGuideBadge)])
      |> or_fail_with("The guide badge needs a link address")
    }),
    it(
      "reports a snippet problem at the block and a guide problem at the heading",
      fn() {
        // Arrange
        let line =
          heading(example_target)
          |> string.replace("/blob/3.0.0/", "/blob/2.4.1/")
        let lines = readme_document(line)

        // Act
        let report = check_readme(lines)

        // Assert
        report.problems
        |> should
        |> be_equal([
          Problem("README.md", 3, WrongTag(found: "2.4.1", expected: "3.0.0")),
          Problem("README.md", 1, MissingGuideBadge),
        ])
        |> or_fail_with("Each problem should be at its own line")
      },
    ),
    it(
      "reports only the missing snippet badge of a heading with a guide badge",
      fn() {
        // Arrange
        let line =
          "### Example <a href=\"https://github.com/TrustBound/dream/blob/3.0.0/"
          <> guide_target
          <> guide_badge_end
        let lines = readme_document(line)

        // Act
        let report = check_readme(lines)

        // Assert
        report.problems
        |> should
        |> be_equal([Problem("README.md", 3, MissingBadgeHeading)])
        |> or_fail_with("The guide badge is checked after the snippet badge")
      },
    ),
  ])
}

fn readme_link_tests() -> UnitNode {
  group("check_readme guide link", [
    it("fails a guide link to another repository", fn() {
      // Arrange
      let line =
        heading(example_target)
        <> " <a href=\"https://github.com/me/other/blob/3.0.0/"
        <> guide_target
        <> guide_badge_end
      let lines = readme_document(line)

      // Act
      let report = check_readme(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem(
          "README.md",
          1,
          ForeignGuideLink(
            "https://github.com/me/other/blob/3.0.0/" <> guide_target,
          ),
        ),
      ])
      |> or_fail_with("The guide must be in the same repository")
    }),
    it("fails a guide link with another tag, and checks the rest", fn() {
      // Arrange
      let line =
        readme_heading(example_target, guide_target)
        |> string.replace(
          "/blob/3.0.0/docs/guides/example.md#example-",
          "/blob/2.4.1/docs/guides/missing.md#example-",
        )
      let lines = readme_document(line)

      // Act
      let report = check_readme(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem(
          "README.md",
          1,
          WrongGuideTag(found: "2.4.1", expected: "3.0.0"),
        ),
        Problem("README.md", 1, MissingGuideFile("docs/guides/missing.md")),
      ])
      |> or_fail_with("The tag and the file should both be reported")
    }),
    it("fails a guide link to a file that is not under a guide directory", fn() {
      // Arrange
      let lines =
        readme_document(readme_heading(
          example_target,
          "docs/example.md#example",
        ))

      // Act
      let report = check_readme(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem(
          "README.md",
          1,
          NotAGuidePath(path: "docs/example.md", guides: ["docs/guides"]),
        ),
      ])
      |> or_fail_with("The guide must be under docs/guides")
    }),
    it("fails a guide link with no anchor", fn() {
      // Arrange
      let lines = readme_document(readme_heading(example_target, guide_path))

      // Act
      let report = check_readme(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("README.md", 1, MissingGuideAnchor(guide_path))])
      |> or_fail_with("The anchor is required")
    }),
    it("fails a guide that cannot be read", fn() {
      // Arrange
      let lines =
        readme_document(readme_heading(
          example_target,
          unreadable_guide_path <> "#example",
        ))

      // Act
      let report = check_readme(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem(
          "README.md",
          1,
          UnreadableFile(path: unreadable_guide_path, reason: simplifile.Eacces),
        ),
      ])
      |> or_fail_with("A guide that cannot be read should fail")
    }),
    it("fails an anchor that is not a heading of the guide", fn() {
      // Arrange
      let lines =
        readme_document(readme_heading(example_target, guide_path <> "#setup"))

      // Act
      let report = check_readme(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem(
          "README.md",
          1,
          GuideAnchorNotFound(path: guide_path, anchor: "setup"),
        ),
      ])
      |> or_fail_with("The anchor must be a heading of the guide")
    }),
    it("fails a guide that does not show the example", fn() {
      // Arrange
      let lines =
        readme_document(readme_heading(
          example_target,
          other_guide_path <> "#setup",
        ))

      // Act
      let report = check_readme(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem(
          "README.md",
          1,
          ExampleNotInGuide(path: other_guide_path, snippet: snippet_path),
        ),
      ])
      |> or_fail_with("The guide must link to the same snippet")
    }),
  ])
}

fn other_document_tests() -> UnitNode {
  group("guide badge outside the README", [
    it("fails a guide badge in another Markdown document", fn() {
      // Arrange
      let lines = readme_document(readme_heading(example_target, guide_target))

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 1, GuideBadgeNotAllowed)])
      |> or_fail_with("Only README examples have the guide badge")
    }),
    it("fails a malformed guide badge in another Markdown document", fn() {
      // Arrange
      let line =
        readme_heading(example_target, guide_target)
        |> string.replace("blue.svg", "green.svg")
      let lines = readme_document(line)

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 1, GuideBadgeNotAllowed)])
      |> or_fail_with("Any guide badge is not allowed here")
    }),
    it("fails a guide badge in a doc comment", fn() {
      // Arrange
      let text =
        readme_document(readme_heading(example_target, guide_target))
        |> list.map(fn(line) { string.trim_end("/// " <> line) })
        |> document

      // Act
      let report = check.check_gleam_source("src/app.gleam", text, context())

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("src/app.gleam", 1, GuideBadgeNotAllowed)])
      |> or_fail_with("Doc comment examples have only the snippet badge")
    }),
    it("fails a guide badge in a changelog", fn() {
      // Arrange
      let text =
        document(readme_document(readme_heading(example_target, guide_target)))

      // Act
      let report = check.check_changelog("CHANGELOG.md", text, context())

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("CHANGELOG.md", 1, GuideBadgeNotAllowed)])
      |> or_fail_with("Changelog examples have only the snippet badge")
    }),
  ])
}

fn parse_tests() -> UnitNode {
  let snippet_address =
    "https://github.com/TrustBound/dream/blob/3.0.0/" <> example_target
  let guide_address =
    "https://github.com/TrustBound/dream/blob/3.0.0/" <> guide_target
  group("parse", [
    it("reads both badges of a README example heading", fn() {
      // Act
      let parsed =
        check.parse_example_heading(readme_heading(example_target, guide_target))

      // Assert
      parsed
      |> should
      |> be_equal(
        Ok(ExampleHeading(
          snippet_address:,
          guide_badge: GuideBadgeLink(guide_address),
        )),
      )
      |> or_fail_with("Both addresses should be read")
    }),
    it("reads a heading with no guide badge", fn() {
      // Act
      let parsed = check.parse_example_heading(heading(example_target))

      // Assert
      parsed
      |> should
      |> be_equal(
        Ok(ExampleHeading(snippet_address:, guide_badge: NoGuideBadge)),
      )
      |> or_fail_with("The guide badge should be absent")
    }),
    it("reads a guide badge in another place as broken", fn() {
      // Arrange
      let line =
        string.replace(
          heading(example_target),
          "### Example",
          "### Example <img alt=\"Guide\">",
        )

      // Act
      let parsed = check.parse_example_heading(line)

      // Assert
      parsed
      |> should
      |> be_equal(
        Ok(ExampleHeading(snippet_address:, guide_badge: BrokenGuideBadge)),
      )
      |> or_fail_with("A guide badge before the snippet badge is broken")
    }),
    it("reads the tag, the path and the anchor of a guide link", fn() {
      // Act
      let link = check.parse_guide_link(guide_address, project().repository)

      // Assert
      link
      |> should
      |> be_equal(
        Ok(GuideLink(tag: "3.0.0", path: guide_path, anchor: "example-")),
      )
      |> or_fail_with("The anchor should be read without its #")
    }),
    it("rejects a guide link out of the repository", fn() {
      // Arrange
      let address =
        "https://github.com/TrustBound/dream/blob/3.0.0/../secret.md#a"

      // Act
      let link = check.parse_guide_link(address, project().repository)

      // Assert
      link
      |> should
      |> be_equal(Error(ForeignGuideLink(address)))
      |> or_fail_with("A path out of the repository should be rejected")
    }),
    it("tells which paths are guides", fn() {
      // Arrange
      let cases = [
        #("docs/guides/a.md", ["docs/guides"]),
        #("docs/guides/deep/a.md", ["docs/guides"]),
        #("docs/guides/a.md", ["docs/guides/"]),
        #("guides/a.md", ["docs/guides", "guides"]),
        #("docs/guides/a.txt", ["docs/guides"]),
        #("docs/guidesx/a.md", ["docs/guides"]),
        #("docs/a.md", ["docs/guides"]),
      ]

      // Act
      let answers =
        list.map(cases, fn(entry) { check.is_guide_path(entry.0, entry.1) })

      // Assert
      answers
      |> should
      |> be_equal([True, True, True, True, False, False, False])
      |> or_fail_with("Only .md files under a guide directory are guides")
    }),
  ])
}

fn anchor_tests() -> UnitNode {
  group("anchors", [
    it("makes GitHub's anchor of each heading text", fn() {
      // Arrange
      let cases = [
        #("Optional Values", "optional-values"),
        #("The `RequestBody` type", "the-requestbody-type"),
        #("What's New", "whats-new"),
        #("HTTP/2 over TLS", "http2-over-tls"),
        #("1. Error types", "1-error-types"),
        #(
          "Check one document <a href=\"https://github.com/me/app/blob/1.0.0/a.gleam\"><img align=\"right\" alt=\"Tested snippet\" src=\"https://img.shields.io/badge/x.svg\"></a>",
          "check-one-document-",
        ),
        #("Read the [guide](https://example.com/a_b) now", "read-the-guide-now"),
        #("Use _emphasis_ and **bold**", "use-emphasis-and-bold"),
        #(
          "The `_private` and `check_markdown` names",
          "the-_private-and-check_markdown-names",
        ),
        #("snake_case names", "snake_case-names"),
        #("Café au lait", "café-au-lait"),
        #("a < b", "a--b"),
        #("Unclosed <tag", "unclosed-tag"),
        #("A [link with no address](", "a-link-with-no-address"),
        #("  Spaces around  ", "spaces-around"),
        #("Read the 📖 guide", "read-the--guide"),
      ]

      // Act
      let slugs = list.map(cases, fn(entry) { check.heading_slug(entry.0) })

      // Assert
      slugs
      |> should
      |> be_equal(list.map(cases, fn(entry) { entry.1 }))
      |> or_fail_with("Each heading should get GitHub's anchor")
    }),
    it("gives the anchors GitHub gives to headings with badge links", fn() {
      // Arrange
      let snippet_badge =
        "<a href=\"https://github.com/me/app/blob/1.0.0/test/snippets/a.gleam\"><img align=\"right\" alt=\"Tested snippet\" src=\"https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square\"></a>"
      let guide_badge =
        "<a href=\"https://github.com/me/app/blob/1.0.0/docs/guides/a.md#a\"><img align=\"right\" alt=\"Guide\" src=\"https://img.shields.io/badge/%F0%9F%93%96_read-guide-blue.svg?style=flat-square\"></a>"
      let text =
        document([
          "## Check one document",
          "### Check one document " <> snippet_badge,
          "### Check a project and read what the command prints "
            <> snippet_badge,
          "### Read the settings from the text of a `gleam.toml` "
            <> snippet_badge,
          "### Check a project and read what the command prints "
            <> snippet_badge
            <> " "
            <> guide_badge,
        ])

      // Act
      let anchors = check.heading_anchors(text)

      // Assert
      anchors
      |> should
      |> be_equal([
        "check-one-document",
        "check-one-document-",
        "check-a-project-and-read-what-the-command-prints-",
        "read-the-settings-from-the-text-of-a-gleamtoml-",
        "check-a-project-and-read-what-the-command-prints--",
      ])
      |> or_fail_with("Each space before a badge link should give a hyphen")
    }),
    it("numbers repeated anchors and reads headings outside fences only", fn() {
      // Arrange
      let text =
        document([
          "# Title", "", "## Setup", "", "```markdown", "## Not a heading",
          "```", "", "## Setup", "## Setup", "### Closing hashes ###",
          "## Language C#", "#No space", "####### Seven",
        ])

      // Act
      let anchors = check.heading_anchors(text)

      // Assert
      anchors
      |> should
      |> be_equal([
        "title", "setup", "setup-1", "setup-2", "closing-hashes", "language-c",
      ])
      |> or_fail_with("Repeated anchors should get -1 and -2")
    }),
  ])
}

fn describe_tests() -> UnitNode {
  group("describe_reason", [
    it("describes every reason of a guide badge", fn() {
      // Arrange
      let reasons = [
        MissingGuideBadge,
        MalformedGuideBadge,
        GuideBadgeNotAllowed,
        ForeignGuideLink("https://example.com/guide.md#a"),
        WrongGuideTag(found: "2.4.1", expected: "3.0.0"),
        NotAGuidePath(path: "docs/a.md", guides: ["docs/guides", "guides"]),
        MissingGuideAnchor("docs/guides/a.md"),
        MissingGuideFile("docs/guides/missing.md"),
        GuideAnchorNotFound(path: "docs/guides/a.md", anchor: "setup"),
        ExampleNotInGuide(path: "docs/guides/a.md", snippet: snippet_path),
      ]

      // Act
      let descriptions = list.map(reasons, check.describe_reason(_, project()))

      // Assert
      descriptions
      |> should
      |> be_equal([
        "this README example heading has no guide badge after its tested snippet badge; copy the heading from docs/contributing/contributing.md",
        "the guide badge is not in the exact format, or it is not directly after the tested snippet badge; copy the heading from docs/contributing/contributing.md",
        "this heading has a guide badge, but only README example headings have one; here the heading has only the tested snippet badge",
        "the guide badge link https://example.com/guide.md#a does not point at a file in https://github.com/TrustBound/dream",
        "the guide badge link uses the tag 2.4.1, but this file must link at the tag 3.0.0 (the docs of dream use the version in gleam.toml)",
        "the guide badge links to docs/a.md, but it must link to a .md file under docs/guides or guides",
        "the guide badge link to docs/guides/a.md has no #<anchor>, but it must name the guide section of this example",
        "the guide badge links to docs/guides/missing.md, which is not a file in this repository",
        "the guide badge links to the anchor #setup, but docs/guides/a.md has no heading with that anchor",
        "docs/guides/a.md has no tested snippet badge that links to test/snippets/example.gleam, but the guide of a README example must show that example",
      ])
      |> or_fail_with("Each guide badge reason should have its message")
    }),
  ])
}
