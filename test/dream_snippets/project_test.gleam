//// Tests for the `dream_snippets` entry module, which checks the files of
//// a real project. Each test writes a small project under
//// `build/fixtures/`.

import dream_snippets.{
  InvalidConfig, ListFailed, MissingRoot, Output, ReadFailed,
}
import dream_snippets/check
import dream_snippets/config.{VersionNotFound}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{type UnitNode, describe, group, it}
import fixtures/project
import gleam/list
import gleam/string
import simplifile

const project_toml =
  "name = \"app\"
version = \"1.1.0\"
repository = { type = \"github\", user = \"me\", repo = \"app\" }

[tools.dream_snippets]
checked_from_version = \"1.1.0\"
"

const snippet_badge_end =
  "\"><img align=\"right\" alt=\"Tested snippet\" src=\"https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square\"></a>"

const guide_badge_end =
  "\"><img align=\"right\" alt=\"Guide\" src=\"https://img.shields.io/badge/%F0%9F%93%96_read-guide-blue.svg?style=flat-square\"></a>"

const diff_badge_end =
  "\"><img align=\"right\" alt=\"Tested diff\" src=\"https://img.shields.io/badge/%F0%9F%A7%AA_tested-diff-lightgreen.svg?style=flat-square\"></a>"

/// Release notes of app 1.1.0 that follow the release notes template.
const release_notes =
  "# app 1.1.0 Release Notes

**Release Date:** 2026-11-20

## Key Highlights

## What's New

## Testing

## Upgrading

### Migration Guide

## Documentation

## Community
"

const old_app = "pub fn name() {\n  \"old\"\n}\n"

const new_app = "pub fn name() {\n  \"new\"\n}\n"

pub fn tests() -> TestSuite {
  describe("dream_snippets", [
    check_project_tests(),
    check_project_error_tests(),
    output_tests(),
    main_tests(),
  ])
}

fn check_project_tests() -> UnitNode {
  group("check_project", [
    it("checks every kind of root, and skips what is out of scope", fn() {
      // Arrange
      let readme =
        "# App\n\n### Hello <a href=\"https://github.com/me/app/blob/1.1.0/test/snippets/hello.gleam"
        <> snippet_badge_end
        <> " <a href=\"https://github.com/me/app/blob/1.1.0/docs/guides/hello.md#hello"
        <> guide_badge_end
        <> "\n\n```gleam\npub fn hello() {\n  \"hi\"\n}\n```\n\n#### Rename <a href=\"https://github.com/me/app/compare/1.0.0...1.1.0#diff-"
        <> check.path_digest("src/app.gleam")
        <> diff_badge_end
        <> "\n\n```diff\n--- a/src/app.gleam\n+++ b/src/app.gleam\n-  \"old\"\n+  \"new\"\n```\n"
      let untested = "```gleam\nx\n```\n"
      let guide =
        "# Hello guide\n\n### Hello <a href=\"https://github.com/me/app/blob/1.1.0/test/snippets/hello.gleam"
        <> snippet_badge_end
        <> "\n\n```gleam\npub fn hello() {\n  \"hi\"\n}\n```\n"
      let assert Ok(directory) =
        project.write_project("project_scope", [
          #("gleam.toml", project_toml),
          #("README.md", readme),
          #("test/snippets/hello.gleam", "pub fn hello() {\n  \"hi\"\n}\n"),
          #("docs/guide.md", "```bash\ngleam run\n```\n"),
          #("docs/guides/hello.md", guide),
          #("docs/deep/more.md", "Text.\n"),
          #("docs/notes.txt", untested),
          #("docs/build/skipped.md", untested),
          #("releases/release-1.0.0.md", untested),
          #("releases/release-1.1.0.md", release_notes),
          #("CHANGELOG.md", "## [1.1.0]\n\nText.\n\n## [1.0.0]\n\n" <> untested),
          #("src/app.gleam", old_app),
        ])
      let assert Ok(Nil) = project.commit_and_tag(directory, "1.0.0")
      let assert Ok(Nil) =
        simplifile.write(to: directory <> "/src/app.gleam", contents: new_app)

      // Act
      let result =
        dream_snippets.output(dream_snippets.check_project(directory))

      // Assert
      result
      |> should
      |> be_equal(Output(
        standard_output: [
          "2 blocks and 1 diff blocks checked in 7 files, 0 problems",
        ],
        standard_error: [],
        exit_status: 0,
      ))
      |> or_fail_with("Only the files in scope should be checked, and pass")
    }),
    it("reports every problem, sorted, and stops with status 1", fn() {
      // Arrange
      let assert Ok(directory) =
        project.write_project("project_problems", [
          #("gleam.toml", project_toml),
          #("docs/a.md", "```text\nimport gleam/io\n```\n"),
          #("README.md", "```gleam\nx\n```\n"),
        ])

      // Act
      let result =
        dream_snippets.output(dream_snippets.check_project(directory))

      // Assert
      result
      |> should
      |> be_equal(Output(
        standard_output: [
          "README.md:1: this gleam code block has no heading with the tested snippet badge directly above it (one blank line between is allowed)",
          "docs/a.md:2: this line looks like Gleam code in a text code fence; put Gleam code in a gleam block with the tested snippet badge",
          "1 blocks and 0 diff blocks checked in 2 files, 2 problems",
        ],
        standard_error: [],
        exit_status: 1,
      ))
      |> or_fail_with("Both problems should be listed before the summary")
    }),
    it(
      "checks the release notes template of checked release notes, with the configured guide",
      fn() {
        // Arrange
        let gleam_toml =
          project_toml <> "release_notes_guide = \"docs/releasing.md\"\n"
        let notes =
          string.replace(release_notes, "## Testing\n\n", "")
          <> "\n```gleam\nx\n```\n"
        let assert Ok(directory) =
          project.write_project("project_release_notes", [
            #("gleam.toml", gleam_toml),
            #("releases/release-1.0.0.md", "Notes.\n"),
            #("releases/release-1.1.0.md", notes),
          ])

        // Act
        let result =
          dream_snippets.output(dream_snippets.check_project(directory))

        // Assert
        result
        |> should
        |> be_equal(Output(
          standard_output: [
            "releases/release-1.1.0.md:1: the section \"## Testing\" is missing, but the template requires it; see \"Release notes template\" in docs/releasing.md",
            "releases/release-1.1.0.md:17: this gleam code block has no heading with the tested snippet badge directly above it (one blank line between is allowed)",
            "1 blocks and 0 diff blocks checked in 1 files, 2 problems",
          ],
          standard_error: [],
          exit_status: 1,
        ))
        |> or_fail_with(
          "The template problem and the block problem should both be listed",
        )
      },
    ),
    it(
      "checks every changelog section and names HexDocs when the table is left out",
      fn() {
        // Arrange
        let gleam_toml =
          "name = \"app\"\nversion = \"1.1.0\"\nrepository = { type = \"github\", user = \"me\", repo = \"app\" }\n"
        let readme =
          "### Hello <img alt=\"Tested snippet\">\n\n```gleam\npub fn hello() {\n  \"hi\"\n}\n```\n"
        let assert Ok(directory) =
          project.write_project("project_defaults", [
            #("gleam.toml", gleam_toml),
            #("README.md", readme),
            #("CHANGELOG.md", "## [0.1.0]\n\n```gleam\nx\n```\n"),
          ])

        // Act
        let result =
          dream_snippets.output(dream_snippets.check_project(directory))

        // Assert
        result
        |> should
        |> be_equal(Output(
          standard_output: [
            "CHANGELOG.md:3: this gleam code block has no heading with the tested snippet badge directly above it (one blank line between is allowed)",
            "README.md:3: the tested snippet badge is not in the exact format; copy it from https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html",
            "2 blocks and 0 diff blocks checked in 2 files, 2 problems",
          ],
          standard_error: [],
          exit_status: 1,
        ))
        |> or_fail_with(
          "The 0.1.0 section should be checked and the message should name HexDocs",
        )
      },
    ),
  ])
}

fn check_project_error_tests() -> UnitNode {
  group("check_project errors", [
    it("fails a project with no gleam.toml", fn() {
      // Arrange
      let assert Ok(directory) =
        project.write_project("project_no_toml", [#("README.md", "Text.\n")])

      // Act
      let result = dream_snippets.check_project(directory)

      // Assert
      result
      |> should
      |> be_equal(Error(ReadFailed("gleam.toml", simplifile.Enoent)))
      |> or_fail_with("A missing gleam.toml should fail")
    }),
    it("fails a gleam.toml with no version", fn() {
      // Arrange
      let assert Ok(directory) =
        project.write_project("project_no_version", [
          #("gleam.toml", "name = \"app\"\n"),
        ])

      // Act
      let result = dream_snippets.check_project(directory)

      // Assert
      result
      |> should
      |> be_equal(Error(InvalidConfig(VersionNotFound)))
      |> or_fail_with("A gleam.toml with no version should fail")
    }),
    it("fails a configured root that does not exist", fn() {
      // Arrange
      let assert Ok(directory) =
        project.write_project("project_missing_root", [
          #(
            "gleam.toml",
            project_toml <> "markdown = [\"README.md\", \"GUIDE.md\"]\n",
          ),
          #("README.md", "Text.\n"),
        ])

      // Act
      let result = dream_snippets.check_project(directory)

      // Assert
      result
      |> should
      |> be_equal(Error(MissingRoot("GUIDE.md")))
      |> or_fail_with("A configured root must exist")
    }),
    it("fails a root that cannot be looked at", fn() {
      // Arrange
      let assert Ok(directory) =
        project.write_project("project_unlistable_root", [
          #("gleam.toml", project_toml <> "markdown = [\"README.md/inner\"]\n"),
          #("README.md", "Text.\n"),
        ])

      // Act
      let result = dream_snippets.check_project(directory)

      // Assert
      result
      |> should
      |> be_equal(Error(ListFailed("README.md/inner", simplifile.Enotdir)))
      |> or_fail_with("A path inside a file should fail")
    }),
    it("fails a document that cannot be read", fn() {
      // Arrange
      let assert Ok(directory) =
        project.write_project("project_unreadable", [
          #("gleam.toml", project_toml),
          #("README.md", "Text.\n"),
        ])
      let assert Ok(Nil) =
        simplifile.set_permissions_octal(directory <> "/README.md", 0o000)

      // Act
      let result = dream_snippets.check_project(directory)

      // Assert
      result
      |> should
      |> be_equal(Error(ReadFailed("README.md", simplifile.Eacces)))
      |> or_fail_with("An unreadable document should fail")
    }),
  ])
}

fn output_tests() -> UnitNode {
  group("output and describe_error", [
    it("prints an error on standard error and stops with status 1", fn() {
      // Arrange
      let result = Error(ReadFailed("gleam.toml", simplifile.Enoent))

      // Act
      let printed = dream_snippets.output(result)

      // Assert
      printed
      |> should
      |> be_equal(Output(
        standard_output: [],
        standard_error: [
          "error: Cannot read gleam.toml: No such file or directory",
        ],
        exit_status: 1,
      ))
      |> or_fail_with("The error should go to standard error")
    }),
    it("describes every error in one line", fn() {
      // Arrange
      let errors = [
        InvalidConfig(VersionNotFound),
        ListFailed("docs", simplifile.Eacces),
        ReadFailed("README.md", simplifile.Eacces),
        MissingRoot("GUIDE.md"),
      ]

      // Act
      let descriptions = list.map(errors, dream_snippets.describe_error)

      // Assert
      descriptions
      |> should
      |> be_equal([
        "gleam.toml has no version = \"...\" line before its first [section].",
        "Cannot list docs: Permission denied",
        "Cannot read README.md: Permission denied",
        "GUIDE.md is set in [tools.dream_snippets] in gleam.toml, but it does not exist",
      ])
      |> or_fail_with("Each error should have its message")
    }),
  ])
}

fn main_tests() -> UnitNode {
  group("main", [
    it("checks this package and returns when there is no problem", fn() {
      // Act
      let result = dream_snippets.main()

      // Assert
      result
      |> should
      |> be_equal(Nil)
      |> or_fail_with("The docs of this package should have no problem")
    }),
  ])
}
