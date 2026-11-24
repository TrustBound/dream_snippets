//// Doc comment: check.heading_anchors
////
//// Lists the anchors of the headings of a document.

import dream_snippets/check

pub fn anchors() -> List(String) {
  // Returns ["my-app", "usage", "usage-1"]
  check.heading_anchors("# My app\n\n## Usage\n\n## Usage\n")
}
