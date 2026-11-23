//// Doc comment: check.summary
////
//// Writes the last line of the output.

import dream_snippets/check

pub fn summary_line() -> String {
  // Returns "12 blocks and 2 diff blocks checked in 9 files, 1 problem"
  check.summary(12, 2, 9, 1)
}
