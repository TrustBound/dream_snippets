//// Doc comment: check.parse_snippet_link
////
//// Reads a tested snippet badge link address.

import dream_snippets/check.{type Reason, type SnippetLink, GitHubRepository}

pub fn snippet_link() -> Result(SnippetLink, Reason) {
  // Returns Ok(SnippetLink(
  //   tag: "1.2.0",
  //   path: "test/snippets/hello.gleam",
  //   anchor: "#L3-L5",
  // ))
  check.parse_snippet_link(
    "https://github.com/me/my_app/blob/1.2.0/test/snippets/hello.gleam#L3-L5",
    GitHubRepository(owner: "me", name: "my_app"),
  )
}
