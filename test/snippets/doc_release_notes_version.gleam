//// Doc comment: check.release_notes_version
////
//// Reads the version from the name of a release notes file.

import dream_snippets/check.{type Version}

pub fn version_of_release_notes() -> Result(Version, Nil) {
  // Returns Ok(Version(major: 3, minor: 0, patch: 0, pre_release: []))
  check.release_notes_version("releases/release-3.0.0.md")
}
