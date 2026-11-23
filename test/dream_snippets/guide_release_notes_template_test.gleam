//// Tests for the "Release notes template" guide
//// (docs/guides/release-notes-template.md). The tests read the complete
//// release notes file from the guide itself, check it and changed copies
//// of it in the example project `my_app` 0.2.0, and assert the exact
//// output that the guide shows.

import dream_snippets.{type Output, Output}
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

fn mistake(name: String, notes: String, expected: List(String)) {
  it(name, fn() {
    // Act
    let output = check_notes(string.replace(name, " ", "_"), notes_path, notes)

    // Assert
    output.standard_output
    |> should
    |> be_equal(expected)
    |> or_fail_with("The check should print the lines of the guide")
  })
}

pub fn tests() -> TestSuite {
  describe("release notes template guide", [
    it("the complete file passes the check", fn() {
      // Act
      let output = check_notes("complete", notes_path, complete_notes())

      // Assert
      output
      |> should
      |> be_equal(Output(
        ["0 blocks and 0 diff blocks checked in 2 files, 0 problems"],
        [],
        0,
      ))
      |> or_fail_with("The complete file should follow the template")
    }),
    mistake(
      "title",
      replace("# my_app 0.2.0 Release Notes", "# my_app 0.1.0 Release Notes\n"),
      [
        "releases/release-0.2.0.md:1: the first line is \"# my_app 0.1.0 Release Notes\", but the template wants the title \"# <Name> 0.2.0 Release Notes\"; see \"Release notes template\" in https://hexdocs.pm/dream_snippets/guides/release-notes-template.html",
        "0 blocks and 0 diff blocks checked in 2 files, 1 problem",
      ],
    ),
    mistake("date", replace("**Release Date:** 2026-11-23", ""), [
      "releases/release-0.2.0.md:1: there is no line that starts with \"**Release Date:**\" between the title and the first section, but the template wants one there; see \"Release notes template\" in https://hexdocs.pm/dream_snippets/guides/release-notes-template.html",
      "0 blocks and 0 diff blocks checked in 2 files, 1 problem",
    ]),
    mistake(
      "unknown",
      replace("## Testing", "## Files changed\n\n## Testing\n"),
      [
        "releases/release-0.2.0.md:17: \"## Files changed\" is not a section of the release notes template; see \"Release notes template\" in https://hexdocs.pm/dream_snippets/guides/release-notes-template.html",
        "0 blocks and 0 diff blocks checked in 2 files, 1 problem",
      ],
    ),
    mistake(
      "order",
      replace("## Testing", "")
        |> string.replace(
          "## Documentation\n",
          "## Testing\n\n## Documentation\n",
        ),
      [
        "releases/release-0.2.0.md:26: \"## Testing\" comes after \"## Upgrading\", but the template has it before \"## Upgrading\"; see \"Release notes template\" in https://hexdocs.pm/dream_snippets/guides/release-notes-template.html",
        "0 blocks and 0 diff blocks checked in 2 files, 1 problem",
      ],
    ),
    mistake("repeated", replace("## Testing", "## What's New\n\n## Testing\n"), [
      "releases/release-0.2.0.md:17: \"## What's New\" is in the file again (first at line 11), but the template has each section one time at most; see \"Release notes template\" in https://hexdocs.pm/dream_snippets/guides/release-notes-template.html",
      "0 blocks and 0 diff blocks checked in 2 files, 1 problem",
    ]),
    mistake(
      "both",
      replace("## Documentation", "## Installing\n\n## Documentation\n"),
      [
        "releases/release-0.2.0.md:27: \"## Upgrading\" and \"## Installing\" are both in the file, but the template allows only one of them; see \"Release notes template\" in https://hexdocs.pm/dream_snippets/guides/release-notes-template.html",
        "0 blocks and 0 diff blocks checked in 2 files, 1 problem",
      ],
    ),
    mistake("missing", replace("## Testing", ""), [
      "releases/release-0.2.0.md:1: the section \"## Testing\" is missing, but the template requires it; see \"Release notes template\" in https://hexdocs.pm/dream_snippets/guides/release-notes-template.html",
      "0 blocks and 0 diff blocks checked in 2 files, 1 problem",
    ]),
    mistake(
      "neither",
      replace("## Upgrading", "") |> string.replace("### Migration Guide\n", ""),
      [
        "releases/release-0.2.0.md:1: neither \"## Upgrading\" nor \"## Installing\" is in the file, but the template requires one of them; see \"Release notes template\" in https://hexdocs.pm/dream_snippets/guides/release-notes-template.html",
        "0 blocks and 0 diff blocks checked in 2 files, 1 problem",
      ],
    ),
    mistake("migration", replace("### Migration Guide", ""), [
      "releases/release-0.2.0.md:21: \"## Upgrading\" has no \"### Migration Guide\", but the template requires it in that section; see \"Release notes template\" in https://hexdocs.pm/dream_snippets/guides/release-notes-template.html",
      "0 blocks and 0 diff blocks checked in 2 files, 1 problem",
    ]),
    it("step 1: old release notes pass after a version bump", fn() {
      // Act
      let output = check_old_notes("release_notes_old", "0.1.0")

      // Assert
      output.standard_output
      |> should
      |> be_equal(["1 block and 0 diff blocks checked in 2 files, 0 problems"])
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
        "1 block and 0 diff blocks checked in 2 files, 1 problem",
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
