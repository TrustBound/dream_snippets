//// Doc comment: check.parse_hunks
////
//// Splits the text of a git diff into its hunks.

import dream_snippets/check.{type DiffHunk}

pub fn hunks() -> List(DiffHunk) {
  let diff_text =
    "diff --git a/src/app.gleam b/src/app.gleam
--- a/src/app.gleam
+++ b/src/app.gleam
@@ -1,3 +1,3 @@
 pub fn name() {
-  \"old\"
+  \"new\"
 }
"
  // Returns [
  //   DiffHunk(header: "@@ -1,3 +1,3 @@", lines: [
  //     " pub fn name() {",
  //     "-  \"old\"",
  //     "+  \"new\"",
  //     " }",
  //   ]),
  // ]
  check.parse_hunks(diff_text)
}
