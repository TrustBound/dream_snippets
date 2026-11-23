//// Tests for the "Tested code blocks" guide
//// (docs/guides/tested-code-blocks.md). Each test runs a snippet of the
//// guide, or checks the example project of the guide, and asserts the
//// exact value or output that the guide shows.

import dream_snippets.{Output}
import dream_snippets/check.{CheckContext, Report, Version}
import dream_snippets/config
import dream_snippets/git
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import fixtures/guide_project.{guide_badge_end, snippet_badge_end}
import simplifile
import snippets/guide_tested_code_blocks_anchor
import snippets/guide_tested_code_blocks_greet_lucy

const snippet_path = "test/snippets/guide_getting_started_greeting.gleam"

const guide_path = "docs/guides/getting-started.md"

/// The guide of the example project, with one tested block.
const guide =
  "# Getting started\n\n### Greet a user <a href=\"https://github.com/me/my_app/blob/0.1.0/test/snippets/guide_getting_started_greeting.gleam\"><img align=\"right\" alt=\"Tested snippet\" src=\"https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square\"></a>\n\n```gleam\nimport gleam/string\n\npub fn greeting(name: String) -> String {\n  \"Hello, \" <> string.capitalise(name) <> \"!\"\n}\n```\n"

/// The README of the example project, with a guide badge that links to the
/// anchor.
fn readme(anchor: String) -> String {
  "# my_app\n\n### Greet a user"
  <> guide_project.snippet_badge_start
  <> "https://github.com/me/my_app/blob/0.1.0/"
  <> snippet_path
  <> snippet_badge_end
  <> " <a href=\"https://github.com/me/my_app/blob/0.1.0/"
  <> guide_path
  <> "#"
  <> anchor
  <> guide_badge_end
  <> "\n\n```gleam\nimport gleam/string\n\npub fn greeting(name: String) -> String {\n  \"Hello, \" <> string.capitalise(name) <> \"!\"\n}\n```\n"
}

/// A guide whose headings show each rule of the anchors.
const anchor_guide =
  "# Greeting users

## What's New

### The `greeting` function

### Greet a user <a href=\"x\"><img alt=\"Tested snippet\"></a>

### Greet a user <a href=\"x\"><img alt=\"Tested snippet\"></a> <a href=\"y\"><img alt=\"Guide\"></a>

## Usage

## Usage
"

pub fn tests() -> TestSuite {
  describe("tested code blocks guide", [
    it("step 2: guide_anchors gives the anchor of each heading", fn() {
      // Act
      let anchors = guide_tested_code_blocks_anchor.guide_anchors(anchor_guide)

      // Assert
      anchors
      |> should
      |> be_equal([
        "greeting-users",
        "whats-new",
        "the-greeting-function",
        "greet-a-user-",
        "greet-a-user--",
        "usage",
        "usage-1",
      ])
      |> or_fail_with("Each heading should get the GitHub anchor")
    }),
    it("step 4: has_anchor finds the anchor with the last hyphen", fn() {
      // Act
      let found =
        guide_tested_code_blocks_anchor.has_anchor(guide, "greet-a-user-")

      // Assert
      found
      |> should
      |> be_equal(True)
      |> or_fail_with("A heading with a badge should end with a hyphen")
    }),
    it("step 4: has_anchor does not find the anchor without it", fn() {
      // Act
      let found =
        guide_tested_code_blocks_anchor.has_anchor(guide, "greet-a-user")

      // Assert
      found
      |> should
      |> be_equal(False)
      |> or_fail_with("The anchor without the hyphen should not exist")
    }),
    it("step 3: the example of the doc comment returns the greeting", fn() {
      // Act
      let greeting = guide_tested_code_blocks_greet_lucy.greet_lucy()

      // Assert
      greeting
      |> should
      |> be_equal("Hello, Lucy!")
      |> or_fail_with("The doc comment example should return the greeting")
    }),
    it("step 3: the doc comment example passes the check", fn() {
      // Arrange
      let source =
        guide_project.read(
          "test/snippets/guide_tested_code_blocks_doc_comment.gleam",
        )
      let assert Ok(configuration) = config.parse(guide_project.gleam_toml)
      let context =
        CheckContext(
          project: configuration.project,
          checked_from_version: Version(0, 0, 0, []),
          read_source: simplifile.read,
          tag_exists: fn(_tag) { Error(git.GitNotFound) },
          diff_from_tag: fn(_tag, _path) { Error(git.GitNotFound) },
          diff_between_tags: fn(_old_tag, _new_tag, _path) {
            Error(git.GitNotFound)
          },
          file_at_tag: fn(_tag, _path) { Error(git.GitNotFound) },
        )

      // Act
      let report = check.check_gleam_source("src/my_app.gleam", source, context)

      // Assert
      report
      |> should
      |> be_equal(
        Report(blocks_checked: 1, diff_blocks_checked: 0, problems: []),
      )
      |> or_fail_with("The doc comment example should pass")
    }),
    it("step 4: a guide badge without the last hyphen fails", fn() {
      // Act
      let output =
        guide_project.check("tested_code_blocks_anchor", [
          #(snippet_path, guide_project.read(snippet_path)),
          #(guide_path, guide),
          #("README.md", readme("greet-a-user")),
        ])

      // Assert
      output
      |> should
      |> be_equal(Output(
        standard_output: [
          "README.md:3: the guide badge links to the anchor #greet-a-user, but docs/guides/getting-started.md has no heading with that anchor",
          "2 blocks and 0 diff blocks checked in 3 files, 1 problem",
        ],
        standard_error: [],
        exit_status: 1,
      ))
      |> or_fail_with("The anchor should be checked against the guide")
    }),
    it("step 5: Gleam code in a text fence fails", fn() {
      // Arrange
      let text_guide =
        "# Usage\n\n```text\nimport my_app/greeting\n```\n\n````markdown\n### Greet a user <a href=\"x\"><img></a>\n````\n"

      // Act
      let output =
        guide_project.check("tested_code_blocks_text_fence", [
          #("docs/guides/usage.md", text_guide),
        ])

      // Assert
      output
      |> should
      |> be_equal(Output(
        standard_output: [
          "docs/guides/usage.md:4: this line looks like Gleam code in a text code fence; put Gleam code in a gleam block with the tested snippet badge",
          "0 blocks and 0 diff blocks checked in 2 files, 1 problem",
        ],
        standard_error: [],
        exit_status: 1,
      ))
      |> or_fail_with("The import should be found in the text fence")
    }),
  ])
}
