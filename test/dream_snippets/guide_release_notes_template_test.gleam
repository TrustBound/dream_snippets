//// Tests for the "Release notes template" guide
//// (docs/guides/release-notes-template.md). The tests read the complete
//// release notes file from the guide itself, check it and changed copies
//// of it in the example project `my_app` 0.2.0, and assert the exact
//// output that the guide shows.

import dream_snippets.{type Output}
import dream_snippets/check.{MissingReleaseNotesSection, Problem}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import fixtures/guide_project
import fixtures/project as fixtures_project
import gleam/list
import gleam/string
import simplifile
import snippets/guide_release_notes_template_test

const guide_path = "docs/guides/release-notes-template.md"

const notes_path = "releases/release-0.2.0.md"

const gleam_toml =
  "name = \"my_app\"
version = \"0.2.0\"
repository = { type = \"github\", user = \"me\", repo = \"my_app\" }
"

/// The complete release notes file of the guide: the first ```markdown
/// fence after the heading `## A complete release notes file`.
fn complete_notes() -> String {
  guide_project.read(guide_path)
  |> string.split("\n")
  |> list.drop_while(fn(line) { line != "## A complete release notes file" })
  |> list.drop_while(fn(line) { line != "```markdown" })
  |> list.drop(1)
  |> list.take_while(fn(line) { line != "```" })
  |> list.map(fn(line) { line <> "\n" })
  |> string.concat
}

/// Checks the example project with release notes at `path`.
fn check_notes(name: String, path: String, notes: String) -> Output {
  guide_project.check("release_notes_" <> name, [
    #("gleam.toml", gleam_toml),
    #(path, notes),
  ])
}

/// The complete file with one line replaced by `replacement`, which can be
/// several lines or none.
fn replace(line: String, replacement: String) -> String {
  string.replace(complete_notes(), line <> "\n", replacement)
}

/// A test of one mistake: the check of `notes` prints the lines of the
/// output file `guide_release_notes_template_<name>`, which the guide shows.
fn mistake(name: String, notes: String) {
  it(name, fn() {
    // Act
    let output = check_notes(name, notes_path, notes)

    // Assert
    guide_project.printed(output)
    |> should
    |> be_equal(guide_project.output_file(
      "guide_release_notes_template_" <> name,
    ))
    |> or_fail_with("The check should print the lines of the guide")
  })
}

pub fn tests() -> TestSuite {
  describe("release notes template guide", [
    it("the complete file passes the check", fn() {
      // Act
      let output = check_notes("complete", notes_path, complete_notes())

      // Assert
      #(guide_project.printed(output), output.exit_status)
      |> should
      |> be_equal(#(
        guide_project.output_file("guide_release_notes_template_complete"),
        0,
      ))
      |> or_fail_with("The complete file should follow the template")
    }),
    mistake(
      "title",
      replace("# my_app 0.2.0 Release Notes", "# my_app 0.1.0 Release Notes\n"),
    ),
    mistake("date", replace("**Release Date:** 2026-11-23", "")),
    mistake(
      "unknown",
      replace("## Testing", "## Files changed\n\n## Testing\n"),
    ),
    mistake(
      "order",
      replace("## Testing", "")
        |> string.replace(
          "## Documentation\n",
          "## Testing\n\n## Documentation\n",
        ),
    ),
    mistake("repeated", replace("## Testing", "## What's New\n\n## Testing\n")),
    mistake(
      "both",
      replace("## Documentation", "## Installing\n\n## Documentation\n"),
    ),
    mistake("missing", replace("## Testing", "")),
    mistake(
      "neither",
      replace("## Upgrading", "") |> string.replace("### Migration Guide\n", ""),
    ),
    mistake("migration", replace("### Migration Guide", "")),
    it("step 1: old release notes pass after a version bump", fn() {
      // Act
      let output = check_old_notes("release_notes_old", "0.1.0")

      // Assert
      output.standard_output
      |> should
      |> be_equal([
        "1 block and 0 diff blocks checked in 2 files, 0 problems; 0 file blocks, 0 command blocks and 0 output blocks checked; 0 illustration blocks",
      ])
      |> or_fail_with("Old notes should be checked at their own tag")
    }),
    it("pitfall: old release notes whose tag is not in the clone", fn() {
      // Act
      let output = check_old_notes("release_notes_old_no_tag", "0.1.0-rc.1")

      // Assert
      output.standard_output
      |> should
      |> be_equal([
        "releases/release-0.1.0.md:11: this block is in the docs of the release 0.1.0, so it is compared with the files at the tag 0.1.0, but that tag is not in this clone; fetch the tags with \"git fetch --tags\" (a shallow clone has none)",
        "1 block and 0 diff blocks checked in 2 files, 1 problem; 0 file blocks, 0 command blocks and 0 output blocks checked; 0 illustration blocks",
      ])
      |> or_fail_with("The notes of 0.1.0 need the tag 0.1.0")
    }),
    it("test your code: the release notes of this package pass", fn() {
      // Act
      let result = guide_release_notes_template_test.release_notes_test()

      // Assert
      result
      |> should
      |> be_equal(Ok([]))
      |> or_fail_with("The release notes of this package should pass")
    }),
    it("test your code: template_problems finds a missing section", fn() {
      // Arrange
      let assert Ok(directory) =
        guide_project_notes(replace("## Community", ""))

      // Act
      let result =
        guide_release_notes_template_test.template_problems(
          directory <> "/" <> notes_path,
        )

      // Assert
      result
      |> should
      |> be_equal(
        Ok([
          Problem(
            directory <> "/" <> notes_path,
            1,
            MissingReleaseNotesSection("Community"),
          ),
        ]),
      )
      |> or_fail_with("template_problems should name the missing section")
    }),
  ])
}

fn guide_project_notes(notes: String) {
  fixtures_project.write_project("guide_release_notes_problems", [
    #(notes_path, notes),
  ])
}

const greeting_path = "test/snippets/guide_getting_started_greeting.gleam"

/// Writes `my_app` 0.1.0 with its release notes, which show the greeting
/// snippet, and tags it `tag`. Then it moves `gleam.toml` to 0.2.0 and
/// changes the snippet, and checks the project.
fn check_old_notes(name: String, tag: String) -> Output {
  let greeting = guide_project.read(greeting_path)
  let old_notes =
    "# my_app 0.1.0 Release Notes\n\n**Release Date:** 2026-10-01\n\n## Key Highlights\n\n## What's New\n\n### Greet a user"
    <> guide_project.snippet_badge_start
    <> "https://github.com/me/my_app/blob/0.1.0/"
    <> greeting_path
    <> guide_project.snippet_badge_end
    <> "\n\n```gleam\nimport gleam/string\n\npub fn greeting(name: String) -> String {\n  \"Hello, \" <> string.capitalise(name) <> \"!\"\n}\n```\n\n## Testing\n\n## Installing\n\n## Documentation\n\n## Community\n"
  let assert Ok(directory) =
    fixtures_project.write_project("guide_" <> name, [
      #("gleam.toml", string.replace(gleam_toml, "0.2.0", "0.1.0")),
      #("src/my_app.gleam", guide_project.main_module),
      #(greeting_path, greeting),
      #("releases/release-0.1.0.md", old_notes),
    ])
  let assert Ok(Nil) = fixtures_project.commit_and_tag(directory, tag)
  let assert Ok(Nil) =
    simplifile.write(to: directory <> "/gleam.toml", contents: gleam_toml)
  let assert Ok(Nil) =
    simplifile.write(
      to: directory <> "/" <> greeting_path,
      contents: string.replace(greeting, "Hello, ", "Hi, "),
    )
  dream_snippets.output(dream_snippets.check_project(directory))
}
