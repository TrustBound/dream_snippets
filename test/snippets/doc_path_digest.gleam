//// Doc comment: check.path_digest
////
//// Makes the digest that names a file in a GitHub compare view.

import dream_snippets/check

pub fn digest() -> String {
  // Returns "8b96d7e46c8e7f38e04701586133706ffc625db241b80e9c73922c10b89804f8"
  check.path_digest("src/app.gleam")
}
