//// Doc comment: check.heading_slug
////
//// Makes the anchor that GitHub gives a heading.

import dream_snippets/check

pub fn anchor() -> String {
  // Returns "the-requestbody-type"
  check.heading_slug("The `RequestBody` type")
}
