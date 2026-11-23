//// Doc comment: check.parse_guide_link
////
//// Reads a guide badge link address.

import dream_snippets/check.{type GuideLink, type Reason, GitHubRepository}

pub fn guide_link() -> Result(GuideLink, Reason) {
  // Returns Ok(GuideLink(
  //   tag: "1.2.0",
  //   path: "docs/guides/hello.md",
  //   anchor: "say-hello",
  // ))
  check.parse_guide_link(
    "https://github.com/me/my_app/blob/1.2.0/docs/guides/hello.md#say-hello",
    GitHubRepository(owner: "me", name: "my_app"),
  )
}
