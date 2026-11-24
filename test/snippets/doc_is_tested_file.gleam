//// Doc comment: check.is_tested_file
////
//// Tells which paths a file block can link to.

import dream_snippets/check
import gleam/list

pub fn tested_paths() -> List(Bool) {
  // Returns [True, True, False]
  list.map(
    [".github/workflows/ci.yml", "Makefile", "docs/example.yml"],
    check.is_tested_file(_, ["test", ".github/", "Makefile"]),
  )
}
