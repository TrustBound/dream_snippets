//// Doc comment: check.changelog_section_name
////
//// Reads the name of a changelog section heading.

import dream_snippets/check

pub fn section_name() -> Result(String, Nil) {
  // Returns Ok("3.0.0")
  check.changelog_section_name("## [3.0.0] - 2026-11-20")
}
