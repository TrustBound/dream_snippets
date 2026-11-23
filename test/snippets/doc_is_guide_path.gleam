//// Doc comment: check.is_guide_path
////
//// Tells which paths are guides.

import dream_snippets/check
import gleam/list

pub fn guide_paths() -> List(Bool) {
  // Returns [True, False, False]
  list.map(
    ["docs/guides/hello.md", "docs/hello.md", "docs/guides/hello.txt"],
    check.is_guide_path(_, ["docs/guides/"]),
  )
}
