//// Doc comment: check.parse_compare_link
////
//// Reads a diff badge link address.

import dream_snippets/check.{type CompareLink, type Reason, GitHubRepository}

pub fn compare_link() -> Result(CompareLink, Reason) {
  // Returns Ok(CompareLink(
  //   old_tag: "1.1.0",
  //   new_tag: "1.2.0",
  //   anchor_digest: "8b96d7e46c8e7f38e04701586133706ffc625db241b80e9c73922c10b89804f8",
  // ))
  check.parse_compare_link(
    "https://github.com/me/my_app/compare/1.1.0...1.2.0#diff-8b96d7e46c8e7f38e04701586133706ffc625db241b80e9c73922c10b89804f8",
    GitHubRepository(owner: "me", name: "my_app"),
  )
}
