//// Doc comment: check.parse_old_code_heading
////
//// Reads the link of a heading with the badge of code at an older release.

import dream_snippets/check.{type Reason, type SnippetLink, GitHubRepository}

pub fn old_code_link() -> Result(SnippetLink, Reason) {
  // Returns Ok(SnippetLink(
  //   tag: "1.1.0",
  //   path: "src/app.gleam",
  //   anchor: "#L3-L5",
  // ))
  check.parse_old_code_heading(
    "### Say hello in 1.1 <a href=\"https://github.com/me/my_app/blob/1.1.0/src/app.gleam#L3-L5\"><img align=\"right\" alt=\"Code at 1.1.0\" src=\"https://img.shields.io/badge/%F0%9F%93%9C_code_at-1.1.0-lightgrey.svg?style=flat-square\"></a>",
    GitHubRepository(owner: "me", name: "my_app"),
  )
}
