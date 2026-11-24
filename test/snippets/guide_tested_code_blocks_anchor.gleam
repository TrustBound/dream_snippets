//// Guide: Tested code blocks, steps 2 and 4
////
//// Finds the anchors that a guide badge can link to.

import dream_snippets/check
import gleam/list

/// The anchors of the headings of a guide, as GitHub makes them.
pub fn guide_anchors(guide: String) -> List(String) {
  check.heading_anchors(guide)
}

/// Tells whether a guide has a heading with the anchor.
pub fn has_anchor(guide: String, anchor: String) -> Bool {
  list.contains(check.heading_anchors(guide), anchor)
}
