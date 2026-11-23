//// Tests for the kinds of code blocks: `check.classify_fence`, and the
//// proof of each kind that is not a `gleam` or `diff` block. File,
//// command and output blocks are copies of tested files, `gleam add` and
//// `gleam deps update` lines name packages of `gleam.toml`, `toml`
//// dependency lines name the release of the document, and an
//// illustration is counted.
////
//// The files and the git history are those of `fixtures/check_context`.

import dream_snippets/check.{
  type Report, BlockDiffers, CheckContext, CommandBlock, DiffBlock,
  ExampleDocumentBlock, FileBlock, ForeignDependency, GleamAddWithoutPackage,
  GleamBlock, HiddenGleamCode, IllustrationBlock, MissingCommandBadgeHeading,
  MissingFileBadgeHeading, MissingGuideBadge, MissingOutputBadgeHeading,
  OutputBlock, Problem, Project, Report, UnclosedFence, UnknownPackage,
  UnlabelledBlock, UnlabelledFence, UnsupportedPackageArgument, UntestedFile,
  WrongDependencyRequirement,
}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{type UnitNode, describe, group, it}
import fixtures/check_context.{
  check, context, document, heading, old_code_heading, old_code_source,
  output_path, output_source, project, script_path, untested_path, workflow_path,
}
import gleam/list
import gleam/string

pub fn tests() -> TestSuite {
  describe("block kinds", [
    classify_tests(),
    file_block_tests(),
    command_block_tests(),
    output_block_tests(),
    illustration_tests(),
    package_tests(),
    dependency_tests(),
    place_tests(),
  ])
}

/// A block of `info` under `heading_line`. The heading is line 1, the
/// fence line 3, and the `body` lines start at line 4.
fn block(
  heading_line: String,
  info: String,
  body: List(String),
) -> List(String) {
  list.flatten([[heading_line, "", "```" <> info], body, ["```"]])
}

/// A block of `info` with no heading: the fence is line 3.
fn bare_block(info: String, body: List(String)) -> List(String) {
  block("Some text.", info, body)
}

/// The lines of a file, without its final newline.
fn lines_of(source: String) -> List(String) {
  source |> string.drop_end(1) |> string.split("\n")
}

fn tested_files() -> List(String) {
  ["test", ".github"]
}

/// The fake context, with the dependencies `gleam_json` and `dream_test`.
fn context_with_dependencies() -> check.CheckContext {
  CheckContext(
    ..context(),
    project: Project(..project(), dependencies: ["gleam_json", "dream_test"]),
  )
}

fn check_packages(body: List(String)) -> Report {
  check.check_markdown(
    "doc.md",
    document(bare_block("sh", body)),
    context_with_dependencies(),
  )
}

fn classify_tests() -> UnitNode {
  group("classify_fence", [
    it("reads gleam, diff and the example documents", fn() {
      // Act
      let kinds =
        list.map(["gleam", "diff", "markdown", "md"], check.classify_fence)

      // Assert
      kinds
      |> should
      |> be_equal([
        GleamBlock,
        DiffBlock,
        ExampleDocumentBlock,
        ExampleDocumentBlock,
      ])
      |> or_fail_with("Each of these languages should have its own kind")
    }),
    it("reads the command languages", fn() {
      // Act
      let kinds =
        list.map(["bash", "sh", "shell", "console"], check.classify_fence)

      // Assert
      kinds
      |> should
      |> be_equal([
        CommandBlock("bash"),
        CommandBlock("sh"),
        CommandBlock("shell"),
        CommandBlock("console"),
      ])
      |> or_fail_with("Each shell language should be a command block")
    }),
    it("reads text as output and any other language as a file", fn() {
      // Act
      let kinds =
        list.map(
          ["text", "yaml", "Dockerfile", "toml title=x"],
          check.classify_fence,
        )

      // Assert
      kinds
      |> should
      |> be_equal([
        OutputBlock,
        FileBlock("yaml"),
        FileBlock("dockerfile"),
        FileBlock("toml"),
      ])
      |> or_fail_with("A new language should be a file block")
    }),
    it("reads the illustration mark after a language", fn() {
      // Act
      let kinds =
        list.map(
          ["text illustration", "sh  illustration", "yaml illustration"],
          check.classify_fence,
        )

      // Assert
      kinds
      |> should
      |> be_equal([
        IllustrationBlock("text"),
        IllustrationBlock("sh"),
        IllustrationBlock("yaml"),
      ])
      |> or_fail_with("A language and the mark should be an illustration")
    }),
    it("never reads gleam, diff or markdown as an illustration", fn() {
      // Act
      let kinds =
        list.map(
          ["gleam illustration", "diff illustration", "markdown illustration"],
          check.classify_fence,
        )

      // Assert
      kinds
      |> should
      |> be_equal([GleamBlock, DiffBlock, ExampleDocumentBlock])
      |> or_fail_with("These kinds should keep their proof")
    }),
    it("reads the mark only as the one word after the language", fn() {
      // Act
      let kinds =
        list.map(
          ["text illustration more", "text Illustration", "illustration", ""],
          check.classify_fence,
        )

      // Assert
      kinds
      |> should
      |> be_equal([
        OutputBlock,
        OutputBlock,
        FileBlock("illustration"),
        UnlabelledBlock,
      ])
      |> or_fail_with("Another form should not be an illustration")
    }),
  ])
}

fn file_block_tests() -> UnitNode {
  group("file blocks", [
    it("passes a copy of a tested file", fn() {
      // Arrange
      let lines =
        block(
          heading(workflow_path),
          "yaml",
          lines_of(check_context.workflow_source),
        )

      // Act
      let report = check(lines)

      // Assert
      report
      |> should
      |> be_equal(Report(..check.empty_report(), file_blocks_checked: 1))
      |> or_fail_with("The copy should pass and count as a file block")
    }),
    it("passes a line range of a tested file", fn() {
      // Arrange
      let lines =
        block(heading(workflow_path <> "#L5-L6"), "yaml", [
          "    steps:",
          "      - run: gleam test",
        ])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([])
      |> or_fail_with("The line range should pass")
    }),
    it("fails a file block with no heading", fn() {
      // Act
      let report = check(bare_block("yaml", ["name: CI"]))

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 3, MissingFileBadgeHeading("yaml"))])
      |> or_fail_with("A file block needs a badge")
    }),
    it("fails a file block on the first line of a document", fn() {
      // Act
      let report = check(["```yaml", "name: CI", "```"])

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 1, MissingFileBadgeHeading("yaml"))])
      |> or_fail_with("A block with nothing above it has no badge")
    }),
    it("says when no tested file is set", fn() {
      // Act
      let message =
        check.describe_reason(UntestedFile("Dockerfile", []), project())

      // Assert
      message
      |> should
      |> be_equal(
        "the badge links to Dockerfile, which is not under a tested_files path (none is set); link to a file that the tests or CI use, and add its path to tested_files in [tools.dream_snippets] in gleam.toml; see docs/contributing/contributing.md",
      )
      |> or_fail_with("An empty list should be named")
    }),
    it("fails a link to a file that is not a tested file", fn() {
      // Arrange
      let lines = block(heading(untested_path), "yaml", ["name: example"])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem("doc.md", 3, UntestedFile(untested_path, tested_files())),
      ])
      |> or_fail_with("The file should be under a tested_files path")
    }),
    it("fails a file block that differs from the file", fn() {
      // Arrange
      let lines =
        block(heading(workflow_path <> "#L1-L2"), "yaml", [
          "name: CI",
          "on: pull",
        ])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem("doc.md", 3, BlockDiffers(workflow_path, "#L1-L2", 5)),
      ])
      |> or_fail_with("The block should be the same as the file")
    }),
    it("fails an unclosed file block with no heading two times", fn() {
      // Arrange
      let lines = ["Some text.", "", "```yaml", "name: CI"]

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem("doc.md", 3, UnclosedFence),
        Problem("doc.md", 3, MissingFileBadgeHeading("yaml")),
      ])
      |> or_fail_with("Both problems should be reported")
    }),
    it("fails code at an older release of a file that is not tested", fn() {
      // Arrange
      let lines =
        block(
          old_code_heading("src/old.gleam"),
          "text",
          lines_of(old_code_source),
        )

      // Act
      let report =
        check.check_markdown("docs/guides/a.md", document(lines), context())

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem(
          "docs/guides/a.md",
          3,
          UntestedFile("src/old.gleam", tested_files()),
        ),
      ])
      |> or_fail_with("Old code of an output block should be a tested file")
    }),
  ])
}

fn command_block_tests() -> UnitNode {
  group("command blocks", [
    it("passes a copy of a script", fn() {
      // Arrange
      let lines = block(heading(script_path <> "#L3"), "sh", ["gleam test"])

      // Act
      let report = check(lines)

      // Assert
      report
      |> should
      |> be_equal(Report(..check.empty_report(), command_blocks_checked: 1))
      |> or_fail_with("The copy should pass and count as a command block")
    }),
    it("fails a command block with no heading", fn() {
      // Act
      let report = check(bare_block("bash", ["make test"]))

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 3, MissingCommandBadgeHeading("bash"))])
      |> or_fail_with("A command block needs a badge")
    }),
    it("fails a block of gleam add lines and another command", fn() {
      // Act
      let report = check_packages(["gleam add gleam_json", "mkdir -p releases"])

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 3, MissingCommandBadgeHeading("sh"))])
      |> or_fail_with("Only a block of package lines needs no badge")
    }),
    it("checks a gleam add block under a badge against the script", fn() {
      // Arrange
      let lines =
        block(heading(script_path <> "#L3"), "sh", ["gleam add dream"])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 3, BlockDiffers(script_path, "#L3", 4))])
      |> or_fail_with("A badge should always be checked")
    }),
  ])
}

fn output_block_tests() -> UnitNode {
  group("output blocks", [
    it("passes a copy of an output file", fn() {
      // Arrange
      let lines = block(heading(output_path), "text", lines_of(output_source))

      // Act
      let report = check(lines)

      // Assert
      report
      |> should
      |> be_equal(Report(..check.empty_report(), output_blocks_checked: 1))
      |> or_fail_with("The copy should pass and count as an output block")
    }),
    it("fails an output block with no heading", fn() {
      // Act
      let report = check(bare_block("text", ["done"]))

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 3, MissingOutputBadgeHeading)])
      |> or_fail_with("An output block needs a badge")
    }),
    it("does not read a Tested source line after an output block", fn() {
      // Arrange
      let lines =
        list.append(
          block(heading(output_path), "text", lines_of(output_source)),
          [
            "",
            "Tested source is a word in this sentence.",
          ],
        )

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([])
      |> or_fail_with("Only a gleam block has the old line")
    }),
  ])
}

fn illustration_tests() -> UnitNode {
  group("illustrations and unlabelled fences", [
    it("counts an illustration", fn() {
      // Act
      let report =
        check(bare_block("text illustration", ["src/", "  app.gleam"]))

      // Assert
      report
      |> should
      |> be_equal(Report(..check.empty_report(), illustration_blocks: 1))
      |> or_fail_with("An illustration should be counted")
    }),
    it("fails Gleam code in an illustration", fn() {
      // Act
      let report =
        check(bare_block("text illustration", ["x", "pub fn main() -> Nil"]))

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 5, HiddenGleamCode("text illustration"))])
      |> or_fail_with("An illustration must not hold Gleam code")
    }),
    it("fails a fence with no language", fn() {
      // Act
      let report = check(bare_block("", ["anything"]))

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 3, UnlabelledFence)])
      |> or_fail_with("A fence with no language cannot be proven")
    }),
  ])
}

fn package_tests() -> UnitNode {
  group("gleam add and gleam deps update", [
    it("passes the package of the project and its dependencies", fn() {
      // Act
      let report =
        check_packages([
          "gleam add dream gleam_json",
          "",
          "gleam add --dev dream_test",
          "gleam deps update dream",
          "gleam deps update",
        ])

      // Assert
      report
      |> should
      |> be_equal(Report(..check.empty_report(), command_blocks_checked: 1))
      |> or_fail_with("Known packages should pass with no badge")
    }),
    it("fails a package that the project does not use", fn() {
      // Act
      let report = check_packages(["gleam add dream", "gleam add --dev mist"])

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 5, UnknownPackage("mist"))])
      |> or_fail_with("An unknown package should fail at its line")
    }),
    it("fails an argument that is not a package name", fn() {
      // Act
      let report =
        check_packages(["gleam add dream@3", "gleam deps update --dev"])

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem("doc.md", 4, UnsupportedPackageArgument("dream@3")),
        Problem("doc.md", 5, UnsupportedPackageArgument("--dev")),
      ])
      |> or_fail_with("Only names, and --dev for gleam add, should pass")
    }),
    it("needs a badge for a command block of blank lines", fn() {
      // Act
      let report = check_packages(["", " "])

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 3, MissingCommandBadgeHeading("sh"))])
      |> or_fail_with("A block with no package line proves nothing")
    }),
    it("fails a gleam add line with no package", fn() {
      // Act
      let report = check_packages(["gleam add --dev"])

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 4, GleamAddWithoutPackage)])
      |> or_fail_with("gleam add should name a package")
    }),
  ])
}

fn dependency_tests() -> UnitNode {
  group("toml dependency lines", [
    it("passes the requirement of the release of the document", fn() {
      // Arrange
      let lines =
        bare_block("toml", [
          "[dependencies]",
          "dream = \">= 3.0.0 and < 4.0.0\"",
          "",
          "[dev-dependencies]",
          "dream = \">= 3.0.0 and < 4.0.0\"",
        ])

      // Act
      let report = check(lines)

      // Assert
      report
      |> should
      |> be_equal(Report(..check.empty_report(), file_blocks_checked: 1))
      |> or_fail_with("The release requirement should pass with no badge")
    }),
    it("fails another requirement", fn() {
      // Arrange
      let lines =
        bare_block("toml", [
          "[dependencies]",
          "dream = \">= 2.0.0 and < 3.0.0\"",
        ])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem(
          "doc.md",
          5,
          WrongDependencyRequirement(
            "dream",
            ">= 2.0.0 and < 3.0.0",
            ">= 3.0.0 and < 4.0.0",
          ),
        ),
      ])
      |> or_fail_with("The requirement should name the release")
    }),
    it("fails another package", fn() {
      // Arrange
      let lines =
        bare_block("toml", [
          "[dependencies]",
          "gleam_json = \">= 3.0.0 and < 4.0.0\"",
        ])

      // Act
      let report =
        check.check_markdown(
          "doc.md",
          document(lines),
          context_with_dependencies(),
        )

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 5, ForeignDependency("gleam_json"))])
      |> or_fail_with("Only the package of the project should pass")
    }),
    it("uses the release of an older changelog section", fn() {
      // Arrange
      let changelog =
        document([
          "# Changelog",
          "",
          "## [2.4.1] - 2026-01-10",
          "",
          "```toml",
          "[dependencies]",
          "dream = \">= 2.4.1 and < 3.0.0\"",
          "```",
        ])
      let older =
        CheckContext(
          ..context(),
          checked_from_version: check.Version(2, 0, 0, []),
        )

      // Act
      let report = check.check_changelog("CHANGELOG.md", changelog, older)

      // Assert
      report.problems
      |> should
      |> be_equal([])
      |> or_fail_with("The section of 2.4.1 should use 2.4.1")
    }),
    it("needs a badge for a toml block of other lines", fn() {
      // Arrange
      let lines =
        bare_block("toml", [
          "dream = \">= 3.0.0 and < 4.0.0\"",
          "[dependencies]",
          "dream = { path = \"..\" }",
        ])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 3, MissingFileBadgeHeading("toml"))])
      |> or_fail_with("Other toml lines need a file")
    }),
    it("needs a badge for a requirement with a quote in it", fn() {
      // Act
      let report =
        check(bare_block("toml", ["[dependencies]", "dream = \"a\" \"b\""]))

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 3, MissingFileBadgeHeading("toml"))])
      |> or_fail_with("A requirement is one quoted text")
    }),
    it("names no next major for a release that is not a version", fn() {
      // Act
      let requirement = check.release_requirement("main")

      // Assert
      requirement
      |> should
      |> be_equal(">= main and < <next major>.0.0")
      |> or_fail_with("The requirement should show the missing major")
    }),
    it("needs a badge for a table line with no requirement", fn() {
      // Act
      let report = check(bare_block("toml", ["[dependencies]"]))

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 3, MissingFileBadgeHeading("toml"))])
      |> or_fail_with("A table line alone proves nothing")
    }),
    it("needs a badge for a value that is not one quoted text", fn() {
      // Arrange
      let lines =
        bare_block("toml", [
          "[dependencies]",
          "Dream = \"1\"",
          "dream = \"a\" \"b\"",
          "dream = 1",
        ])

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 3, MissingFileBadgeHeading("toml"))])
      |> or_fail_with("Only dependency lines are proven with no file")
    }),
  ])
}

fn place_tests() -> UnitNode {
  group("blocks in every place", [
    it("checks a file block in a markdown example", fn() {
      // Arrange
      let lines = [
        "````markdown",
        "# Example",
        "",
        "```yaml",
        "name: x",
        "```",
        "````",
      ]

      // Act
      let report = check(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("doc.md", 4, MissingFileBadgeHeading("yaml"))])
      |> or_fail_with("A fence in an example document should be checked")
    }),
    it("checks a command block in a doc comment", fn() {
      // Arrange
      let source =
        "/// Runs it.\n///\n/// ```sh\n/// make test\n/// ```\npub fn run() {\n  Nil\n}\n"

      // Act
      let report = check.check_gleam_source("src/app.gleam", source, context())

      // Assert
      report.problems
      |> should
      |> be_equal([
        Problem("src/app.gleam", 3, MissingCommandBadgeHeading("sh")),
      ])
      |> or_fail_with("A doc comment block should be checked")
    }),
    it("needs a guide badge on a file block of the README", fn() {
      // Arrange
      let lines = block(heading(workflow_path <> "#L1"), "yaml", ["name: CI"])

      // Act
      let report = check_context.check_readme(lines)

      // Assert
      report.problems
      |> should
      |> be_equal([Problem("README.md", 1, MissingGuideBadge)])
      |> or_fail_with("A README example has a guide badge")
    }),
  ])
}
