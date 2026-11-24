//// Guide: Tested code blocks, step 7
////
//// A test helper that compares the real output with the output file that
//// the guide shows.

import gleam/string
import simplifile
import snippets/guide_tested_code_blocks_anchor

/// Tells whether the output file holds the anchors of the guide, as
/// `string.inspect` writes them, with a line break at the end.
pub fn anchors_match_output_file(guide: String) -> Bool {
  let real =
    string.inspect(guide_tested_code_blocks_anchor.guide_anchors(guide))
  let shown =
    simplifile.read("test/outputs/guide_tested_code_blocks_anchors.txt")
  shown == Ok(real <> "\n")
}
