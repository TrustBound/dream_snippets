//// Tests for the "Getting started" guide (docs/guides/getting-started.md).
//// Each test writes the example project of the guide under
//// `build/fixtures/`, checks it as the command does, and asserts the exact
//// output that the guide shows.

import dream_snippets.{type Output, Output}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import fixtures/guide_project
import gleam/list
import gleam/string
import simplifile
import snippets/guide_getting_started_greeting
import snippets/guide_getting_started_greeting_test

const readme = "# my_app\n\nSays hello.\n"

const snippet_path = "test/snippets/guide_getting_started_greeting.gleam"

/// The heading that the guide shows for the example, with its badge.
const heading =
  "### Greet a user <a href=\"https://github.com/me/my_app/blob/0.1.0/test/snippets/guide_getting_started_greeting.gleam\"><img align=\"right\" alt=\"Tested snippet\" src=\"https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square\"></a>"

/// The README heading that the guide shows, with both badges.
const readme_heading =
  "### Greet a user <a href=\"https://github.com/me/my_app/blob/0.1.0/test/snippets/guide_getting_started_greeting.gleam\"><img align=\"right\" alt=\"Tested snippet\" src=\"https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square\"></a> <a href=\"https://github.com/me/my_app/blob/0.1.0/docs/guides/getting-started.md#greet-a-user-\"><img align=\"right\" alt=\"Guide\" src=\"https://img.shields.io/badge/%F0%9F%93%96_read-guide-blue.svg?style=flat-square\"></a>"

/// The code of the snippet without its `////` module comment, as the docs
/// show it.
const code =
  "import gleam/string

pub fn greeting(name: String) -> String {
  \"Hello, \" <> string.capitalise(name) <> \"!\"
}
"

fn guide(heading_line: String) -> String {
  "# Getting started\n\n" <> heading_line <> "\n\n```gleam\n" <> code <> "```\n"
}

fn readme_with(heading_line: String) -> String {
  "# my_app\n\nSays hello.\n\n"
  <> heading_line
  <> "\n\n```gleam\n"
  <> code
  <> "```\n"
}

/// Checks the example project with the snippet and the files of a step.
fn check(name: String, files: List(#(String, String))) -> Output {
  let snippet = guide_project.read(snippet_path)
  let without_snippet = list.filter(files, fn(file) { file.0 != snippet_path })
  let snippet_file = case list.key_find(files, snippet_path) {
    Ok(text) -> #(snippet_path, text)
    Error(Nil) -> #(snippet_path, snippet)
  }
  guide_project.check("getting_started_" <> name, [
    snippet_file,
    ..without_snippet
  ])
}

pub fn tests() -> TestSuite {
  describe("getting started guide", [
    it("step 1: a project with no code blocks passes", fn() {
      // Act
      let output = check("step_1", [#("README.md", readme)])

      // Assert
      output
      |> should
      |> be_equal(Output(
        standard_output: [
          "0 blocks and 0 diff blocks checked in 2 files, 0 problems",
        ],
        standard_error: [],
        exit_status: 0,
      ))
      |> or_fail_with("The first run should count the files and pass")
    }),
    it("step 2: greeting capitalises the name", fn() {
      // Act
      let greeting = guide_getting_started_greeting.greeting("lucy")

      // Assert
      greeting
      |> should
      |> be_equal("Hello, Lucy!")
      |> or_fail_with("greeting should capitalise the name")
    }),
    it("step 2: the test of the snippet passes", fn() {
      // Act
      let result = guide_getting_started_greeting_test.greeting_test()

      // Assert
      result
      |> should
      |> be_equal("Hello, Lucy!")
      |> or_fail_with("The test of the snippet should pass")
    }),
    it("step 3: the snippet file is the code that the guide shows", fn() {
      // Act
      let snippet = simplifile.read(snippet_path)

      // Assert
      snippet
      |> should
      |> be_equal(Ok(
        "//// Guide: Getting started, step 2\n////\n//// The code that the guide of the example project shows.\n\n"
        <> code,
      ))
      |> or_fail_with("The snippet should be the code of the guide")
    }),
    it("step 4: the guide with the tested block passes", fn() {
      // Act
      let output =
        check("step_4", [
          #("README.md", readme),
          #("docs/guides/getting-started.md", guide(heading)),
        ])

      // Assert
      output
      |> should
      |> be_equal(Output(
        standard_output: [
          "1 block and 0 diff blocks checked in 3 files, 0 problems",
        ],
        standard_error: [],
        exit_status: 0,
      ))
      |> or_fail_with("The guide should pass")
    }),
    it("step 5: a changed snippet fails the check", fn() {
      // Arrange
      let snippet = guide_project.read(snippet_path)
      let changed = string.replace(snippet, "Hello, ", "Hi, ")

      // Act
      let output =
        check("step_5", [
          #("README.md", readme),
          #("docs/guides/getting-started.md", guide(heading)),
          #(snippet_path, changed),
        ])

      // Assert
      output
      |> should
      |> be_equal(Output(
        standard_output: [
          "docs/guides/getting-started.md:5: the code block is not the same as test/snippets/guide_getting_started_greeting.gleam; the first difference is at line 9",
          "1 block and 0 diff blocks checked in 3 files, 1 problem",
        ],
        standard_error: [],
        exit_status: 1,
      ))
      |> or_fail_with("The old block should fail")
    }),
    it("step 5: a block with no heading fails the check", fn() {
      // Act
      let output =
        check("step_5_heading", [
          #("README.md", readme),
          #("docs/guides/getting-started.md", guide("### Greet a user")),
        ])

      // Assert
      output
      |> should
      |> be_equal(Output(
        standard_output: [
          "docs/guides/getting-started.md:5: this gleam code block has no heading with the tested snippet badge directly above it (one blank line between is allowed)",
          "1 block and 0 diff blocks checked in 3 files, 1 problem",
        ],
        standard_error: [],
        exit_status: 1,
      ))
      |> or_fail_with("The block with no badge should fail")
    }),
    it("step 6: a README example with no guide badge fails", fn() {
      // Act
      let output =
        check("step_6_no_guide", [
          #("README.md", readme_with(heading)),
          #("docs/guides/getting-started.md", guide(heading)),
        ])

      // Assert
      output
      |> should
      |> be_equal(Output(
        standard_output: [
          "README.md:5: this README example heading has no guide badge after its tested snippet badge; copy the heading from https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html",
          "2 blocks and 0 diff blocks checked in 3 files, 1 problem",
        ],
        standard_error: [],
        exit_status: 1,
      ))
      |> or_fail_with("The README example needs the guide badge")
    }),
    it("step 6: a README example with both badges passes", fn() {
      // Act
      let output =
        check("step_6", [
          #("README.md", readme_with(readme_heading)),
          #("docs/guides/getting-started.md", guide(heading)),
        ])

      // Assert
      output
      |> should
      |> be_equal(Output(
        standard_output: [
          "2 blocks and 0 diff blocks checked in 3 files, 0 problems",
        ],
        standard_error: [],
        exit_status: 0,
      ))
      |> or_fail_with("The README example should pass")
    }),
  ])
}
