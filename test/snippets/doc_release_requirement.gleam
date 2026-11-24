//// Doc comment: check.release_requirement
////
//// Writes the requirement of a release.

import dream_snippets/check

pub fn requirement() -> String {
  // Returns ">= 2.1.0-rc.1 and < 3.0.0"
  check.release_requirement("2.1.0-rc.1")
}
