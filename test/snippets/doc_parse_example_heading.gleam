//// Doc comment: check.parse_example_heading
////
//// Reads the tested snippet badge and the guide badge of a heading.

import dream_snippets/check.{type ExampleHeading, type Reason}

pub fn example_heading() -> Result(ExampleHeading, Reason) {
  // Returns Ok(ExampleHeading(
  //   snippet_address: "https://github.com/me/my_app/blob/1.2.0/test/snippets/hello.gleam",
  //   guide_badge: GuideBadgeLink(
  //     "https://github.com/me/my_app/blob/1.2.0/docs/guides/hello.md#say-hello",
  //   ),
  // ))
  check.parse_example_heading(
    "### Say hello <a href=\"https://github.com/me/my_app/blob/1.2.0/test/snippets/hello.gleam\"><img align=\"right\" alt=\"Tested snippet\" src=\"https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square\"></a> <a href=\"https://github.com/me/my_app/blob/1.2.0/docs/guides/hello.md#say-hello\"><img align=\"right\" alt=\"Guide\" src=\"https://img.shields.io/badge/%F0%9F%93%96_read-guide-blue.svg?style=flat-square\"></a>",
  )
}
