//// Doc comment: check.parse_line_selection
////
//// Reads a line anchor.

import dream_snippets/check.{type LineSelection, type Reason}

pub fn line_range() -> Result(LineSelection, Reason) {
  // Returns Ok(LineRange(start: 3, end: 5))
  check.parse_line_selection("#L3-L5")
}
