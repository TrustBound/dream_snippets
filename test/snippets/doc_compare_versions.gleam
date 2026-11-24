//// Doc comment: check.compare_versions
////
//// Puts a release candidate before its release, as semver does.

import dream_snippets/check.{AlphanumericIdentifier, NumericIdentifier, Version}
import gleam/order.{type Order}

pub fn compare_release_candidate() -> Order {
  let release_candidate =
    Version(2, 0, 0, [AlphanumericIdentifier("rc"), NumericIdentifier(1)])
  // Returns order.Lt, because a pre-release comes before its release
  check.compare_versions(release_candidate, Version(2, 0, 0, []))
}
