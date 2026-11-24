//// Doc comment: check.is_safe_path
////
//// Tells which paths are safe to give to git.

import dream_snippets/check
import gleam/list

pub fn safe_paths() -> List(Bool) {
  // Returns [True, False, False]
  list.map(["src/app.gleam", "../secret.txt", "-p"], check.is_safe_path)
}
