//// Doc comment: check.is_safe_tag
////
//// Tells which tag names are safe to give to git.

import dream_snippets/check
import gleam/list

pub fn safe_tags() -> List(Bool) {
  // Returns [True, False, False]
  list.map(["1.2.0", "-x", "1..2"], check.is_safe_tag)
}
