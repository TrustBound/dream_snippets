//// Doc comment: check.is_checked_changelog_section
////
//// Tells which changelog sections are checked.

import dream_snippets/check.{Version}
import gleam/list

pub fn checked_sections() -> List(Bool) {
  let checked_from_version = Version(1, 0, 0, [])
  // Returns [True, False, True]
  list.map(["Unreleased", "0.9.0", "1.2.0"], check.is_checked_changelog_section(
    _,
    checked_from_version,
  ))
}
