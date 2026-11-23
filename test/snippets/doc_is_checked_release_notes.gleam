//// Doc comment: check.is_checked_release_notes
////
//// Tells which release notes files are checked.

import dream_snippets/check.{Version}
import gleam/list

pub fn checked_release_notes() -> List(Bool) {
  let checked_from_version = Version(2, 0, 0, [])
  // Returns [True, False, False]
  list.map(
    ["releases/release-10.0.0.md", "releases/release-1.4.0.md", "README.md"],
    check.is_checked_release_notes(_, checked_from_version),
  )
}
