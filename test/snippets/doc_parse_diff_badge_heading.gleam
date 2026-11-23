//// Doc comment: check.parse_diff_badge_heading
////
//// Reads the link address of the diff badge of a heading.

import dream_snippets/check.{type Reason}

pub fn diff_badge_address() -> Result(String, Reason) {
  // Returns Ok("https://github.com/me/my_app/compare/1.1.0...1.2.0#diff-8b96d7e46c8e7f38e04701586133706ffc625db241b80e9c73922c10b89804f8")
  check.parse_diff_badge_heading(
    "### Rename the function <a href=\"https://github.com/me/my_app/compare/1.1.0...1.2.0#diff-8b96d7e46c8e7f38e04701586133706ffc625db241b80e9c73922c10b89804f8\"><img align=\"right\" alt=\"Tested diff\" src=\"https://img.shields.io/badge/%F0%9F%A7%AA_tested-diff-lightgreen.svg?style=flat-square\"></a>",
  )
}
