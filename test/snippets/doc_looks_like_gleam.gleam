//// Doc comment: check.looks_like_gleam
////
//// Tells which lines look like Gleam code.

import dream_snippets/check
import gleam/list

pub fn gleam_lines() -> List(Bool) {
  // Returns [True, False, True]
  list.map(
    ["import gleam/io", "npm install", "pub fn main() {"],
    check.looks_like_gleam,
  )
}
