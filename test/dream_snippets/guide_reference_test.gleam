//// Tests for the "Settings and checks reference" page
//// (docs/guides/reference.md). They read the two TOML examples of the
//// page and assert what `config.parse` makes of them.

import dream_snippets/check.{Version}
import dream_snippets/config
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import fixtures/guide_project
import gleam/list
import gleam/result

/// The `[tools.dream_snippets]` table of the defaults, as the page and
/// the doc comment of `dream_snippets/config` show it.
fn defaults_table() -> String {
  "
" <> guide_project.read("test/fixtures/settings/defaults.toml")
}

/// The table of the project with tested docs from 1.1.0 on.
fn two_settings_table() -> String {
  "
" <> guide_project.read("test/fixtures/settings/two_settings.toml")
}

pub fn tests() -> TestSuite {
  describe("settings and checks reference", [
    it("the defaults table gives the same project as no table", fn() {
      // Act
      let projects =
        [
          guide_project.gleam_toml() <> defaults_table(),
          guide_project.gleam_toml(),
        ]
        |> list.map(fn(text) {
          config.parse(text) |> result.map(fn(parsed) { parsed.project })
        })

      // Assert
      case projects {
        [with_table, without_table] -> with_table == without_table
        _ -> False
      }
      |> should
      |> be_equal(True)
      |> or_fail_with("The table should hold the default settings")
    }),
    it("the defaults table names the default roots", fn() {
      // Act
      let paths =
        config.parse(guide_project.gleam_toml() <> defaults_table())
        |> result.map(fn(parsed) {
          list.map(parsed.roots, fn(root) { root.path })
        })

      // Assert
      paths
      |> should
      |> be_equal(Ok(list.map(config.default_roots(), fn(root) { root.path })))
      |> or_fail_with("The table should list the default paths")
    }),
    it("two settings change the version and the badge guide", fn() {
      // Act
      let settings =
        config.parse(guide_project.gleam_toml() <> two_settings_table())
        |> result.map(fn(parsed) {
          #(parsed.checked_from_version, parsed.project.badge_guide)
        })

      // Assert
      settings
      |> should
      |> be_equal(Ok(#(Version(1, 1, 0, []), "docs/contributing.md")))
      |> or_fail_with("The two settings should be read")
    }),
  ])
}
