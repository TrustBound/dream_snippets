//// Tests for the "Show an API change in an upgrade guide" guide
//// (docs/guides/upgrade-guides.md). Each test writes the example project
//// at the release 0.1.0, tags it with real git, changes it to 0.2.0, and
//// checks the upgrade guide that the guide shows.

import dream_snippets.{type Output}
import dream_snippets/check
import dream_snippets/git.{Git}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import fixtures/guide_project
import fixtures/project
import gleam/list
import gleam/string
import simplifile

const old_toml =
  "name = \"my_app\"
version = \"0.1.0\"
repository = { type = \"github\", user = \"me\", repo = \"my_app\" }
"

const new_toml =
  "name = \"my_app\"
version = \"0.2.0\"
repository = { type = \"github\", user = \"me\", repo = \"my_app\" }
"

const old_module =
  "pub fn greeting(name: String) -> String {
  \"Hello, \" <> name <> \"!\"
}
"

const new_module =
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

const old_snippet =
  "import my_app

pub fn greet_lucy() -> String {
  my_app.greeting(\"Lucy\")
}
"

const new_snippet =
  "import my_app.{Formal}

pub fn greet_lucy() -> String {
  my_app.greeting(\"Lucy\", Formal)
}
"

const snippet_path = "test/snippets/guide_upgrading_greet_lucy.gleam"

const guide_path = "docs/guides/upgrading.md"

/// The upgrade guide that the guide shows, with the tag of the old code,
/// the anchor of the diff badge, and the diff lines.
fn upgrade_guide(
  old_tag: String,
  digest: String,
  diff_lines: String,
) -> String {
  "# Upgrading to 0.2.0

## Greeting takes a style

### Before: greet Lucy <a href=\"https://github.com/me/my_app/blob/" <> old_tag <> "/test/snippets/guide_upgrading_greet_lucy.gleam#L4\"><img align=\"right\" alt=\"Code at " <> old_tag <> "\" src=\"https://img.shields.io/badge/%F0%9F%93%9C_code_at-" <> old_tag <> "-lightgrey.svg?style=flat-square\"></a>

```gleam
  my_app.greeting(\"Lucy\")
```

### After: greet Lucy <a href=\"https://github.com/me/my_app/blob/0.2.0/test/snippets/guide_upgrading_greet_lucy.gleam#L4\"><img align=\"right\" alt=\"Tested snippet\" src=\"https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square\"></a>

```gleam
  my_app.greeting(\"Lucy\", Formal)
```

#### The new signature <a href=\"https://github.com/me/my_app/compare/0.1.0...0.2.0#diff-" <> digest <> "\"><img align=\"right\" alt=\"Tested diff\" src=\"https://img.shields.io/badge/%F0%9F%A7%AA_tested-diff-lightgreen.svg?style=flat-square\"></a>

```diff
--- a/src/my_app.gleam
+++ b/src/my_app.gleam
" <> diff_lines <> "```
"
}

const diff_lines =
  "-pub fn greeting(name: String) -> String {
-  \"Hello, \" <> name <> \"!\"
+pub fn greeting(name: String, style: Style) -> String {
+  case style {
"

/// Writes the project at 0.1.0, tags it, changes it to 0.2.0 with the
/// upgrade guide, and checks it.
fn check_upgrade(
  name: String,
  tag: String,
  guide: String,
  extra_files: List(#(String, String)),
) -> Output {
  let assert Ok(directory) =
    project.write_project("guide_upgrade_" <> name, [
      #("gleam.toml", old_toml),
      #("src/my_app.gleam", old_module),
      #(snippet_path, old_snippet),
    ])
  let assert Ok(Nil) = project.commit_and_tag(directory, tag)
  let new_files =
    list.append(
      [
        #("gleam.toml", new_toml),
        #("src/my_app.gleam", new_module),
        #(snippet_path, new_snippet),
        #(guide_path, guide),
      ],
      extra_files,
    )
  let assert Ok(Nil) =
    simplifile.create_directory_all(directory <> "/docs/guides")
  let assert Ok(Nil) =
    list.try_each(new_files, fn(file) {
      simplifile.write(to: directory <> "/" <> file.0, contents: file.1)
    })
  dream_snippets.output(dream_snippets.check_project(directory))
}

fn digest() -> String {
  check.path_digest("src/my_app.gleam")
}

pub fn tests() -> TestSuite {
  describe("upgrade guides guide", [
    it("the digest names src/my_app.gleam in the compare view", fn() {
      // Act
      let anchor = digest()

      // Assert
      anchor
      |> should
      |> be_equal(
        "dc300fec45bded4a328557d8cdb35d83594380337bd562985800e8086dc62ebd",
      )
      |> or_fail_with("The digest should be the SHA-256 of the path")
    }),
    it("step 4: the upgrade guide passes", fn() {
      // Act
      let output =
        check_upgrade(
          "passes",
          "0.1.0",
          upgrade_guide("0.1.0", digest(), diff_lines),
          [],
        )

      // Assert
      #(guide_project.printed(output), output.exit_status)
      |> should
      |> be_equal(#(guide_project.output_file("guide_upgrade_guides_passes"), 0))
      |> or_fail_with("The upgrade guide should pass")
    }),
    it("step 3: git diff shows the change of the signature", fn() {
      // Arrange
      let assert Ok(directory) =
        project.write_project("guide_upgrade_git_diff", [
          #("gleam.toml", old_toml),
          #("src/my_app.gleam", old_module),
        ])
      let assert Ok(Nil) = project.commit_and_tag(directory, "0.1.0")
      let assert Ok(Nil) =
        simplifile.write(
          to: directory <> "/src/my_app.gleam",
          contents: new_module,
        )

      // Act
      let diff =
        git.run(Git(program: "git", directory:), [
          "-c", "core.pager=cat", "diff", "--no-color", "0.1.0", "--",
          "src/my_app.gleam",
        ])

      // Assert
      diff
      |> should
      |> be_equal(
        Ok(guide_project.output_file("guide_upgrade_guides_git_diff")),
      )
      |> or_fail_with("The diff should be the one the guide shows")
    }),
    it("fails when the old tag is not in the clone", fn() {
      // Act
      let output =
        check_upgrade(
          "missing_tag",
          "0.1.0-rc.1",
          upgrade_guide("0.1.0", digest(), diff_lines),
          [],
        )

      // Assert
      #(guide_project.printed(output), output.exit_status)
      |> should
      |> be_equal(#(guide_project.output_file("guide_upgrade_guides_no_tag"), 1))
      |> or_fail_with("A missing tag should fail both blocks")
    }),
    it("fails old code at the current version", fn() {
      // Act
      let output =
        check_upgrade(
          "current_version",
          "0.1.0",
          upgrade_guide("0.2.0", digest(), diff_lines),
          [],
        )

      // Assert
      #(guide_project.printed(output), output.exit_status)
      |> should
      |> be_equal(#(
        guide_project.output_file("guide_upgrade_guides_current_version"),
        1,
      ))
      |> or_fail_with("Old code must be at an older release")
    }),
    it("fails a diff line that is not in the real diff", fn() {
      // Act
      let output =
        check_upgrade(
          "wrong_line",
          "0.1.0",
          upgrade_guide(
            "0.1.0",
            digest(),
            string.replace(
              diff_lines,
              "style: Style",
              "style: Style, loud: Bool",
            ),
          ),
          [],
        )

      // Assert
      #(guide_project.printed(output), output.exit_status)
      |> should
      |> be_equal(#(
        guide_project.output_file("guide_upgrade_guides_diff_line"),
        1,
      ))
      |> or_fail_with("The changed line should not be in the diff")
    }),
    it("fails a diff badge with the anchor of another file", fn() {
      // Act
      let output =
        check_upgrade(
          "wrong_anchor",
          "0.1.0",
          upgrade_guide("0.1.0", check.path_digest("src/app.gleam"), diff_lines),
          [],
        )

      // Assert
      #(guide_project.printed(output), output.exit_status)
      |> should
      |> be_equal(#(guide_project.output_file("guide_upgrade_guides_anchor"), 1))
      |> or_fail_with("The anchor should name the file of the block")
    }),
    it("fails old code in the README", fn() {
      // Arrange
      let readme =
        "# my_app\n\n### Before <a href=\"https://github.com/me/my_app/blob/0.1.0/test/snippets/guide_upgrading_greet_lucy.gleam#L4\"><img align=\"right\" alt=\"Code at 0.1.0\" src=\"https://img.shields.io/badge/%F0%9F%93%9C_code_at-0.1.0-lightgrey.svg?style=flat-square\"></a>\n\n```gleam\n  my_app.greeting(\"Lucy\")\n```\n"

      // Act
      let output =
        check_upgrade(
          "readme",
          "0.1.0",
          upgrade_guide("0.1.0", digest(), diff_lines),
          [#("README.md", readme)],
        )

      // Assert
      #(guide_project.printed(output), output.exit_status)
      |> should
      |> be_equal(#(guide_project.output_file("guide_upgrade_guides_readme"), 1))
      |> or_fail_with("The README shows only current code")
    }),
  ])
}
