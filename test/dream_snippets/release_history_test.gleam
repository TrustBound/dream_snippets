//// Tests for the docs of older releases: release notes and changelog
//// sections keep passing after a version bump.
////
//// Each test writes a project with real git: `my_app` at 0.1.0 (tag
//// 0.1.0), then at 0.2.0 (tag 0.2.0), then the working tree at 0.3.0. The
//// module and the snippet change at each release, so a block of the 0.2.0
//// docs is only the same as the files at the tag 0.2.0.

import dream_snippets.{type Output, Output}
import dream_snippets/check
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{type UnitNode, describe, group, it}
import fixtures/project
import gleam/list
import gleam/string
import simplifile

fn gleam_toml(version: String) -> String {
  "name = \"my_app\"
version = \"" <> version <> "\"
repository = { type = \"github\", user = \"me\", repo = \"my_app\" }
"
}

const module_0_1_0 =
  "pub fn greeting(name: String) -> String {
  \"Hello, \" <> name <> \"!\"
}
"

const module_0_2_0 =
  "pub fn greeting(name: String, style: Style) -> String {
  case style {
    Casual -> \"Hi, \" <> name <> \"!\"
    Formal -> \"Hello, \" <> name <> \".\"
  }
}

pub type Style {
  Casual
  Formal
}
"

const module_0_3_0 =
  "pub fn greeting(name: String, style: Style) -> String {
  case style {
    Friendly -> \"Hi, \" <> name <> \"!\"
    Formal -> \"Hello, \" <> name <> \".\"
  }
}

pub type Style {
  Friendly
  Formal
}
"

const snippet_path = "test/snippets/greet_lucy.gleam"

fn snippet(call: String) -> String {
  "import my_app

pub fn greet_lucy() -> String {
  " <> call <> "
}
"
}

const call_0_1_0 = "my_app.greeting(\"Lucy\")"

const call_0_2_0 = "my_app.greeting(\"Lucy\", my_app.Casual)"

const call_0_3_0 = "my_app.greeting(\"Lucy\", my_app.Friendly)"

const snippet_badge_end =
  "\"><img align=\"right\" alt=\"Tested snippet\" src=\"https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square\"></a>"

const diff_badge_end =
  "\"><img align=\"right\" alt=\"Tested diff\" src=\"https://img.shields.io/badge/%F0%9F%A7%AA_tested-diff-lightgreen.svg?style=flat-square\"></a>"

/// A heading with the tested snippet badge for line 4 of the snippet at
/// `tag`.
fn snippet_heading(tag: String) -> String {
  "### Greet Lucy <a href=\"https://github.com/me/my_app/blob/"
  <> tag
  <> "/"
  <> snippet_path
  <> "#L4"
  <> snippet_badge_end
}

/// A heading with the "code at an older release" badge for line 4 of the
/// snippet at `tag`.
fn old_code_heading(tag: String) -> String {
  "### Before <a href=\"https://github.com/me/my_app/blob/"
  <> tag
  <> "/"
  <> snippet_path
  <> "#L4\"><img align=\"right\" alt=\"Code at "
  <> tag
  <> "\" src=\"https://img.shields.io/badge/%F0%9F%93%9C_code_at-"
  <> string.replace(tag, "-", "--")
  <> "-lightgrey.svg?style=flat-square\"></a>"
}

/// A heading with the tested diff badge for `src/my_app.gleam` in the
/// compare view `range`.
fn diff_heading(range: String) -> String {
  "### The change <a href=\"https://github.com/me/my_app/compare/"
  <> range
  <> "#diff-"
  <> check.path_digest("src/my_app.gleam")
  <> diff_badge_end
}

/// A gleam block under `heading`: the heading, a blank line, the fence and
/// one code line.
fn gleam_block(heading: String, call: String) -> String {
  heading <> "\n\n```gleam\n  " <> call <> "\n```\n"
}

/// A diff block of `src/my_app.gleam` under `heading`.
fn diff_block(heading: String, lines: List(String)) -> String {
  heading
  <> "\n\n```diff\n--- a/src/my_app.gleam\n+++ b/src/my_app.gleam\n"
  <> string.join(lines, "\n")
  <> "\n```\n"
}

/// Lines of the real diff from 0.1.0 to 0.2.0.
const diff_0_2_0 = [
  "+pub fn greeting(name: String, style: Style) -> String {",
  "+  case style {",
  "+    Casual -> \"Hi, \" <> name <> \"!\"",
]

/// Lines of the real diff from 0.2.0 to 0.3.0.
const diff_0_3_0 = [
  "-    Casual -> \"Hi, \" <> name <> \"!\"",
  "+    Friendly -> \"Hi, \" <> name <> \"!\"",
]

/// Release notes that follow the template, with `body` in "What's New".
/// The title is line 1 and the body starts at line 9.
fn release_notes(version: String, body: String) -> String {
  "# my_app "
  <> version
  <> " Release Notes\n\n**Release Date:** 2026-10-01\n\n## Key Highlights\n\n## What's New\n\n"
  <> body
  <> "\n## Testing\n\n## Installing\n\n## Documentation\n\n## Community\n"
}

/// The release notes of 0.2.0 that pass: a snippet block at line 11, code
/// at 0.1.0 at line 17, and a diff block at line 23.
fn notes_0_2_0() -> String {
  release_notes(
    "0.2.0",
    gleam_block(snippet_heading("0.2.0"), call_0_2_0)
      <> "\n"
      <> gleam_block(old_code_heading("0.1.0"), call_0_1_0)
      <> "\n"
      <> diff_block(diff_heading("0.1.0...0.2.0"), diff_0_2_0),
  )
}

/// The release notes of 0.3.0 that pass: a snippet block at line 11, and
/// a diff block at line 17.
fn notes_0_3_0() -> String {
  release_notes(
    "0.3.0",
    gleam_block(snippet_heading("0.3.0"), call_0_3_0)
      <> "\n"
      <> diff_block(diff_heading("0.2.0...0.3.0"), diff_0_3_0),
  )
}

/// Writes the project at 0.1.0 and tags it `first_tag`, then at 0.2.0 and
/// tags it `second_tag`, then writes the working tree at `version` with
/// the docs, and checks it.
fn check_history(
  name: String,
  tags: #(String, String),
  version: String,
  docs: List(#(String, String)),
) -> Output {
  let #(first_tag, second_tag) = tags
  let assert Ok(directory) =
    project.write_project("release_history_" <> name, [
      #("gleam.toml", gleam_toml("0.1.0")),
      #("src/my_app.gleam", module_0_1_0),
      #(snippet_path, snippet(call_0_1_0)),
    ])
  let assert Ok(Nil) = project.commit_and_tag(directory, first_tag)
  let assert Ok(Nil) =
    write_files(directory, [
      #("gleam.toml", gleam_toml("0.2.0")),
      #("src/my_app.gleam", module_0_2_0),
      #(snippet_path, snippet(call_0_2_0)),
    ])
  let assert Ok(Nil) = project.commit_again_and_tag(directory, second_tag)
  let assert Ok(Nil) =
    write_files(
      directory,
      list.append(
        [
          #("gleam.toml", gleam_toml(version)),
          #("src/my_app.gleam", module_0_3_0),
          #(snippet_path, snippet(call_0_3_0)),
        ],
        docs,
      ),
    )
  dream_snippets.output(dream_snippets.check_project(directory))
}

fn write_files(
  directory: String,
  files: List(#(String, String)),
) -> Result(Nil, simplifile.FileError) {
  list.try_each(files, fn(file) {
    let path = directory <> "/" <> file.0
    let parent =
      path |> string.split("/") |> list.reverse |> list.drop(1) |> list.reverse
    let assert Ok(Nil) =
      simplifile.create_directory_all(string.join(parent, "/"))
    simplifile.write(to: path, contents: file.1)
  })
}

/// Checks the docs at 0.3.0 with the tags 0.1.0 and 0.2.0.
fn check_at_0_3_0(name: String, docs: List(#(String, String))) -> Output {
  check_history(name, #("0.1.0", "0.2.0"), "0.3.0", docs)
}

fn failed(lines: List(String)) -> Output {
  Output(standard_output: lines, standard_error: [], exit_status: 1)
}

fn passed(summary: String) -> Output {
  Output(standard_output: [summary], standard_error: [], exit_status: 0)
}

pub fn tests() -> TestSuite {
  describe("docs of older releases", [
    release_notes_tests(),
    changelog_tests(),
    pre_release_tests(),
  ])
}

fn release_notes_tests() -> UnitNode {
  group("release notes", [
    it("old and current release notes pass after the version bump", fn() {
      // Act
      let output =
        check_at_0_3_0("notes_pass", [
          #("releases/release-0.2.0.md", notes_0_2_0()),
          #("releases/release-0.3.0.md", notes_0_3_0()),
        ])

      // Assert
      output
      |> should
      |> be_equal(passed(
        "3 blocks and 2 diff blocks checked in 3 files, 0 problems",
      ))
      |> or_fail_with("Old release notes should be checked at their own tag")
    }),
    it("fails an old block that shows the code of the working tree", fn() {
      // Arrange
      let notes =
        release_notes(
          "0.2.0",
          gleam_block(snippet_heading("0.2.0"), call_0_3_0),
        )

      // Act
      let output =
        check_at_0_3_0("notes_differs", [#("releases/release-0.2.0.md", notes)])

      // Assert
      output
      |> should
      |> be_equal(
        failed([
          "releases/release-0.2.0.md:11: the code block is not the same as test/snippets/greet_lucy.gleam#L4 at the tag 0.2.0; the first difference is at line 12",
          "1 block and 0 diff blocks checked in 2 files, 1 problem",
        ]),
      )
      |> or_fail_with("The block should be compared with the file at 0.2.0")
    }),
    it("fails an old badge that links at the current version", fn() {
      // Arrange
      let notes =
        release_notes(
          "0.2.0",
          gleam_block(snippet_heading("0.3.0"), call_0_2_0),
        )

      // Act
      let output =
        check_at_0_3_0("notes_wrong_tag", [
          #("releases/release-0.2.0.md", notes),
        ])

      // Assert
      output
      |> should
      |> be_equal(
        failed([
          "releases/release-0.2.0.md:11: the badge link uses the tag 0.3.0, but this file must link at the tag 0.2.0 (release notes and changelog sections link at the tag of their own release)",
          "1 block and 0 diff blocks checked in 2 files, 1 problem",
        ]),
      )
      |> or_fail_with("Old release notes link at their own release")
    }),
    it("fails an old diff that ends at the current version", fn() {
      // Arrange
      let notes =
        release_notes(
          "0.2.0",
          diff_block(diff_heading("0.1.0...0.3.0"), diff_0_2_0),
        )

      // Act
      let output =
        check_at_0_3_0("notes_wrong_new_tag", [
          #("releases/release-0.2.0.md", notes),
        ])

      // Assert
      output
      |> should
      |> be_equal(
        failed([
          "releases/release-0.2.0.md:11: the compare link ends at the tag 0.3.0, but this file must use the new tag 0.2.0 (release notes and changelog sections link at the tag of their own release)",
          "0 blocks and 1 diff block checked in 2 files, 1 problem",
        ]),
      )
      |> or_fail_with("An old diff ends at the release of its notes")
    }),
    it("fails an old diff line that is not in the diff between the tags", fn() {
      // Arrange
      let notes =
        release_notes(
          "0.2.0",
          diff_block(diff_heading("0.1.0...0.2.0"), [
            "+pub fn greeting(name: String, style: Style) -> String {",
            "+  case style {",
            "+    Friendly -> \"Hi, \" <> name <> \"!\"",
          ]),
        )

      // Act
      let output =
        check_at_0_3_0("notes_wrong_diff_line", [
          #("releases/release-0.2.0.md", notes),
        ])

      // Assert
      output
      |> should
      |> be_equal(
        failed([
          "releases/release-0.2.0.md:16: this line is not in \"git diff 0.1.0 0.2.0 -- src/my_app.gleam\" at this place; a diff block shows lines of the real diff, in order and contiguous within a hunk",
          "0 blocks and 1 diff block checked in 2 files, 1 problem",
        ]),
      )
      |> or_fail_with("An old diff is the diff between the two tags")
    }),
    it("fails old release notes when their tag is not in the clone", fn() {
      // Act
      let output =
        check_history("notes_missing_tag", #("0.1.0", "0.2.0-rc.1"), "0.3.0", [
          #("releases/release-0.2.0.md", notes_0_2_0()),
        ])

      // Assert
      output
      |> should
      |> be_equal(
        failed([
          "releases/release-0.2.0.md:11: this block is in the docs of the release 0.2.0, so it is compared with the files at the tag 0.2.0, but that tag is not in this clone; fetch the tags with \"git fetch --tags\" (a shallow clone has none)",
          "releases/release-0.2.0.md:23: this block is in the docs of the release 0.2.0, so it is compared with the files at the tag 0.2.0, but that tag is not in this clone; fetch the tags with \"git fetch --tags\" (a shallow clone has none)",
          "2 blocks and 1 diff block checked in 2 files, 2 problems",
        ]),
      )
      |> or_fail_with("A missing release tag should fail the snippet and diff")
    }),
    it("fails release notes of a release after the version", fn() {
      // Arrange
      let notes =
        release_notes(
          "0.4.0",
          gleam_block(snippet_heading("0.4.0"), call_0_3_0),
        )

      // Act
      let output =
        check_at_0_3_0("notes_future", [#("releases/release-0.4.0.md", notes)])

      // Assert
      output
      |> should
      |> be_equal(
        failed([
          "releases/release-0.4.0.md:11: this block is in the docs of the release 0.4.0, which is neither 0.3.0, the version in gleam.toml, nor a release before it; set the version in gleam.toml to the release that these docs are for",
          "1 block and 0 diff blocks checked in 2 files, 1 problem",
        ]),
      )
      |> or_fail_with("Docs of a later release cannot be checked")
    }),
  ])
}

/// A changelog with a section for 0.3.0 and one for 0.2.0. The 0.3.0
/// block is at line 7, its diff at line 13, and the 0.2.0 section starts
/// at line 22.
fn changelog(section_0_2_0: String) -> String {
  "# Changelog\n\n## [0.3.0] - 2026-11-01\n\n"
  <> gleam_block(snippet_heading("0.3.0"), call_0_3_0)
  <> "\n"
  <> diff_block(diff_heading("0.2.0...0.3.0"), diff_0_3_0)
  <> "\n## [0.2.0] - 2026-10-01\n\n"
  <> section_0_2_0
}

fn changelog_tests() -> UnitNode {
  group("changelog sections", [
    it("old and current sections pass after the version bump", fn() {
      // Arrange
      let section =
        gleam_block(snippet_heading("0.2.0"), call_0_2_0)
        <> "\n"
        <> diff_block(diff_heading("0.1.0...0.2.0"), diff_0_2_0)

      // Act
      let output =
        check_at_0_3_0("changelog_pass", [
          #("CHANGELOG.md", changelog(section)),
        ])

      // Assert
      output
      |> should
      |> be_equal(passed(
        "2 blocks and 2 diff blocks checked in 2 files, 0 problems",
      ))
      |> or_fail_with("An old section should be checked at its own tag")
    }),
    it("fails an old section block that shows the working tree", fn() {
      // Arrange
      let section = gleam_block(snippet_heading("0.2.0"), call_0_3_0)

      // Act
      let output =
        check_at_0_3_0("changelog_differs", [
          #("CHANGELOG.md", changelog(section)),
        ])

      // Assert
      output
      |> should
      |> be_equal(
        failed([
          "CHANGELOG.md:24: the code block is not the same as test/snippets/greet_lucy.gleam#L4 at the tag 0.2.0; the first difference is at line 25",
          "2 blocks and 1 diff block checked in 2 files, 1 problem",
        ]),
      )
      |> or_fail_with("The old section should be compared with the tag")
    }),
    it("checks the Unreleased section at the version", fn() {
      // Arrange
      let text =
        "# Changelog\n\n## [Unreleased]\n\n"
        <> gleam_block(snippet_heading("0.3.0"), call_0_2_0)

      // Act
      let output =
        check_at_0_3_0("changelog_unreleased", [#("CHANGELOG.md", text)])

      // Assert
      output
      |> should
      |> be_equal(
        failed([
          "CHANGELOG.md:7: the code block is not the same as test/snippets/greet_lucy.gleam#L4; the first difference is at line 8",
          "1 block and 0 diff blocks checked in 2 files, 1 problem",
        ]),
      )
      |> or_fail_with("Unreleased should be compared with the working tree")
    }),
  ])
}

fn pre_release_tests() -> UnitNode {
  group("pre-releases", [
    it("shows code at a release candidate of the version", fn() {
      // Arrange
      let guide =
        "# Upgrading\n\n"
        <> gleam_block(old_code_heading("0.3.0-rc.1"), call_0_2_0)

      // Act
      let output =
        check_history(
          "pre_release_old_code",
          #("0.1.0", "0.3.0-rc.1"),
          "0.3.0",
          [#("docs/guides/upgrading.md", guide)],
        )

      // Assert
      output
      |> should
      |> be_equal(passed(
        "1 block and 0 diff blocks checked in 2 files, 0 problems",
      ))
      |> or_fail_with("0.3.0-rc.1 is a release before 0.3.0")
    }),
    it("checks release notes of a release candidate at its tag", fn() {
      // Arrange
      let notes =
        release_notes(
          "0.3.0-rc.1",
          gleam_block(snippet_heading("0.3.0-rc.1"), call_0_2_0),
        )

      // Act
      let output =
        check_history("pre_release_notes", #("0.1.0", "0.3.0-rc.1"), "0.3.0", [
          #("releases/release-0.3.0-rc.1.md", notes),
        ])

      // Assert
      output
      |> should
      |> be_equal(passed(
        "1 block and 0 diff blocks checked in 2 files, 0 problems",
      ))
      |> or_fail_with("The notes of 0.3.0-rc.1 belong to an older release")
    }),
  ])
}
