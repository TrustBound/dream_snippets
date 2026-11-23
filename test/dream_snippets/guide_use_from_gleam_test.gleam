//// Tests for the "Use it from Gleam" guide (docs/guides/use-from-gleam.md).
//// Each test runs a snippet of the guide against the example project of
//// the guides, written under `build/fixtures/`, and asserts the exact
//// value that the guide shows.

import dream_snippets.{type Output, MissingRoot}
import dream_snippets/check
import dream_snippets/config
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import fixtures/guide_project
import fixtures/project
import gleam/list
import gleam/string
import snippets/doc_check_project
import snippets/guide_use_from_gleam_annotations
import snippets/guide_use_from_gleam_context
import snippets/guide_use_from_gleam_docs_test

const guide =
  "# Usage\n\n### Greet a user\n\n```gleam\nmy_app.greeting(\"Lucy\")\n```\n"

pub fn tests() -> TestSuite {
  describe("use it from gleam guide", [
    it("step 1: summary_of returns the lines that the command prints", fn() {
      // Arrange
      let assert Ok(directory) =
        project.write_project("guide_use_summary", [
          #("gleam.toml", guide_project.gleam_toml()),
          #("docs/guides/usage.md", guide),
        ])

      // Act
      let lines = doc_check_project.summary_of(directory)

      // Assert
      string.concat(list.map(lines, fn(line) { line <> "\n" }))
      |> should
      |> be_equal(guide_project.output_file("guide_use_from_gleam_summary"))
      |> or_fail_with("summary_of should return the problem and the summary")
    }),
    it("step 2: docs_test passes on the docs of this repository", fn() {
      // Act
      let lines = guide_use_from_gleam_docs_test.docs_test()

      // Assert
      lines
      |> list.map(string.contains(_, ", 0 problems;"))
      |> should
      |> be_equal([True])
      |> or_fail_with("The docs of this repository should have no problem")
    }),
    it("step 3: annotations gives one annotation for each problem", fn() {
      // Arrange
      let assert Ok(directory) =
        project.write_project("guide_use_annotations", [
          #("gleam.toml", guide_project.gleam_toml()),
          #("docs/guides/usage.md", guide),
        ])

      // Act
      let lines = guide_use_from_gleam_annotations.annotations(directory)

      // Assert
      { string.inspect(lines) <> "\n" }
      |> should
      |> be_equal(guide_project.output_file("guide_use_from_gleam_annotations"))
      |> or_fail_with("Each problem should be an annotation")
    }),
    it("step 3: annotations returns the error that stops the check", fn() {
      // Arrange
      let assert Ok(directory) =
        project.write_project("guide_use_no_toml", [#("README.md", "# x\n")])

      // Act
      let result =
        guide_use_from_gleam_annotations.annotations(directory)
        |> result_error_message

      // Assert
      { result <> "\n" }
      |> should
      |> be_equal(guide_project.output_file("guide_use_from_gleam_no_toml"))
      |> or_fail_with("The error should name the missing gleam.toml")
    }),
    it("step 5: context_for finds a tag of the real repository", fn() {
      // Arrange
      let assert Ok(directory) =
        project.write_project("guide_use_context", [
          #("gleam.toml", guide_project.gleam_toml()),
        ])
      let assert Ok(Nil) = project.commit_and_tag(directory, "0.1.0")
      let assert Ok(configuration) = config.parse(guide_project.gleam_toml())
      let context =
        guide_use_from_gleam_context.context_for(directory, configuration)

      // Act
      let found = context.tag_exists("0.1.0")

      // Assert
      found
      |> should
      |> be_equal(Ok(True))
      |> or_fail_with("The context should run git in the project")
    }),
    it("step 5: context_for reads the snippet files of the project", fn() {
      // Arrange
      let snippet_path = "test/snippets/guide_getting_started_greeting.gleam"
      let tested_guide =
        "# Usage\n\n### Greet a user"
        <> guide_project.snippet_badge_start
        <> "https://github.com/me/my_app/blob/0.1.0/"
        <> snippet_path
        <> guide_project.snippet_badge_end
        <> "\n\n```gleam\n"
        <> string.replace(
          guide_project.read(snippet_path),
          each: "//// Guide: Getting started, step 2\n////\n//// The code that the guide of the example project shows.\n\n",
          with: "",
        )
        <> "```\n"
      let assert Ok(directory) =
        project.write_project("guide_use_context_read", [
          #("gleam.toml", guide_project.gleam_toml()),
          #(snippet_path, guide_project.read(snippet_path)),
        ])
      let assert Ok(configuration) = config.parse(guide_project.gleam_toml())
      let context =
        guide_use_from_gleam_context.context_for(directory, configuration)

      // Act
      let report =
        check.check_markdown("docs/guides/usage.md", tested_guide, context)

      // Assert
      report
      |> should
      |> be_equal(
        check.Report(
          ..check.empty_report(),
          blocks_checked: 1,
          diff_blocks_checked: 0,
          problems: [],
        ),
      )
      |> or_fail_with("The context should read the snippet from the project")
    }),
    it("errors: a root that is set and missing stops the check", fn() {
      // Act
      let output = dream_snippets.output(Error(MissingRoot("docs")))

      // Assert
      #(guide_project.printed(output), output.exit_status)
      |> should
      |> be_equal(#(
        guide_project.output_file("guide_use_from_gleam_missing_root"),
        1,
      ))
      |> or_fail_with("A missing root should be an error")
    }),
    it("errors: an unknown setting stops the check", fn() {
      // Arrange
      let assert Ok(directory) =
        project.write_project("guide_use_unknown_setting", [
          #(
            "gleam.toml",
            guide_project.gleam_toml()
              <> "\n[tools.dream_snippets]\nguide = [\"docs\"]\n",
          ),
        ])

      // Act
      let output: Output =
        dream_snippets.output(dream_snippets.check_project(directory))

      // Assert
      #(guide_project.printed(output), output.exit_status)
      |> should
      |> be_equal(#(
        guide_project.output_file("guide_use_from_gleam_unknown_setting"),
        1,
      ))
      |> or_fail_with("An unknown setting should be an error")
    }),
  ])
}

fn result_error_message(
  result: Result(a, dream_snippets.CheckError),
) -> String {
  case result {
    Ok(_) -> "no error"
    Error(error) -> dream_snippets.describe_error(error)
  }
}
