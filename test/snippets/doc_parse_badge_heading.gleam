//// Doc comment: check.parse_badge_heading
////
//// Reads the link address of the tested snippet badge of a heading.

import dream_snippets/check.{type Reason}

pub fn badge_address() -> Result(String, Reason) {
  // Returns Ok("https://github.com/me/my_app/blob/1.2.0/test/snippets/hello.gleam")
  check.parse_badge_heading(
    "### Say hello <a href=\"https://github.com/me/my_app/blob/1.2.0/test/snippets/hello.gleam\"><img align=\"right\" alt=\"Tested snippet\" src=\"https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square\"></a>",
  )
}
