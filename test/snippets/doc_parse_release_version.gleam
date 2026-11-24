//// Doc comment: check.parse_release_version
////
//// Reads a version, with a pre-release part.

import dream_snippets/check.{type Version}

pub fn release_candidate_version() -> Result(Version, Nil) {
  // Returns Ok(Version(major: 3, minor: 1, patch: 0, pre_release: [
  //   AlphanumericIdentifier("rc"),
  //   NumericIdentifier(1),
  // ]))
  check.parse_release_version("3.1.0-rc.1")
}
