//// Fixtures for the tests of `dream_snippets/check`: a fake project, fake
//// snippet files and a fake git history, and builders for small inline
//// documents. The tests never read real docs, snippets or history.

import dream_snippets/check.{
  type CheckContext, type Project, type Report, CheckContext, GitHubRepository,
  Project, Version,
}
import dream_snippets/git.{type GitError}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import simplifile

pub const snippet_path = "test/snippets/example.gleam"

/// A snippet file with a module comment. Line 8 is indented.
pub const snippet_source =
  "//// An example snippet.

import gleam/io

pub const answer = 42

pub fn main() {
  io.println(\"hi\")
}
"

/// A snippet file with no module comment and no final newline.
pub const plain_snippet_path = "test/snippets/plain.gleam"

pub const plain_snippet_source =
  "import gleam/io

pub fn main() {
  io.println(\"hi\")
}"

/// A snippet file whose module comment has no blank line after it.
pub const tight_snippet_path = "test/snippets/tight.gleam"

pub const tight_snippet_source =
  "//// A tight snippet.
pub const answer = 42
"

/// A snippet file that cannot be read.
pub const unreadable_path = "test/snippets/locked.gleam"

pub const badge_end =
  "\"><img align=\"right\" alt=\"Tested snippet\" src=\"https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square\"></a>"

pub const diff_badge_end =
  "\"><img align=\"right\" alt=\"Tested diff\" src=\"https://img.shields.io/badge/%F0%9F%A7%AA_tested-diff-lightgreen.svg?style=flat-square\"></a>"

pub const guide_badge_end =
  "\"><img align=\"right\" alt=\"Guide\" src=\"https://img.shields.io/badge/%F0%9F%93%96_read-guide-blue.svg?style=flat-square\"></a>"

/// A guide that shows the example of `snippet_path`. Its anchors are
/// `example-guide`, `example-` and `café-au-lait`.
pub const guide_path = "docs/guides/example.md"

/// A guide that does not show the example. Its anchors are `other-guide`
/// and `setup`.
pub const other_guide_path = "docs/guides/other.md"

/// A guide that cannot be read.
pub const unreadable_guide_path = "docs/guides/locked.md"

/// The file with a diff in the fake history: it changed between the tag
/// 2.4.1 and the working tree.
pub const diff_path = "src/app.gleam"

/// The fake output of `git diff 2.4.1 -- src/app.gleam`.
pub const fake_diff =
  "diff --git a/src/app.gleam b/src/app.gleam
index 1111111..2222222 100644
--- a/src/app.gleam
+++ b/src/app.gleam
@@ -1,4 +1,4 @@
 import gleam/io
-import gleam/option.{None, Some}
+import dream/http/request.{Stream}
 import gleam/yielder
@@ -10,5 +10,5 @@ pub fn upload(
 pub fn upload(request) {
-  case request.stream {
-    Some(chunks) -> save(chunks)
+  case request.body {
+    Stream(chunks) -> save(chunks)
   }
"

/// A file whose fake diff has a hunk header with no closing `@@` and no
/// final newline.
pub const odd_diff_path = "src/odd.gleam"

pub const odd_diff =
  "@@ odd
-old line"

/// The file with code at the tag 2.4.1 in the fake history. Line 3 is
/// indented, and the file ends with a newline.
pub const old_code_path = "src/old.gleam"

pub const old_code_source =
  "pub fn upload(request) {
  case request.stream {
    Some(chunks) -> save(chunks)
  }
}
"

/// The project of the fake context: dream at 3.0.0.
pub fn project() -> Project {
  Project(
    name: "dream",
    version: "3.0.0",
    repository: GitHubRepository(owner: "TrustBound", name: "dream"),
    badge_guide: "docs/contributing/contributing.md",
    release_notes_guide: "docs/contributing/release-notes.md",
    guides: ["docs/guides"],
  )
}

/// The fake output of `git diff 2.3.0 2.4.1 -- src/app.gleam`.
pub const fake_diff_between_tags =
  "diff --git a/src/app.gleam b/src/app.gleam
index 0000000..1111111 100644
--- a/src/app.gleam
+++ b/src/app.gleam
@@ -1,3 +1,3 @@
 import gleam/io
-import gleam/option.{type Option}
+import gleam/option.{None, Some}
 import gleam/yielder
"

/// A context with the snippet files above, the tags 2.3.0 and 2.4.1, and
/// the fake diffs above.
pub fn context() -> CheckContext {
  CheckContext(
    project: project(),
    checked_from_version: Version(3, 0, 0, []),
    read_source: read_fake_source,
    tag_exists: fn(tag) { Ok(tag == "2.4.1" || tag == "2.3.0") },
    diff_from_tag: fake_diff_from_tag,
    diff_between_tags: fake_diff_between,
    file_at_tag: fake_file_at_tag,
  )
}

fn fake_diff_between(
  old_tag: String,
  new_tag: String,
  path: String,
) -> Result(String, GitError) {
  case old_tag, new_tag, path {
    "2.3.0", "2.4.1", "src/app.gleam" -> Ok(fake_diff_between_tags)
    _, _, _ -> Ok("")
  }
}

fn read_fake_source(path: String) -> Result(String, simplifile.FileError) {
  let files = [
    #(snippet_path, snippet_source),
    #(plain_snippet_path, plain_snippet_source),
    #(tight_snippet_path, tight_snippet_source),
    #(guide_path, guide_source()),
    #(other_guide_path, "# Other guide\n\n## Setup\n"),
  ]
  case path == unreadable_path || path == unreadable_guide_path {
    True -> Error(simplifile.Eacces)
    False ->
      list.key_find(files, path) |> result.replace_error(simplifile.Enoent)
  }
}

fn fake_diff_from_tag(tag: String, path: String) -> Result(String, GitError) {
  case tag, path {
    "2.4.1", "src/app.gleam" -> Ok(fake_diff)
    "2.4.1", "src/odd.gleam" -> Ok(odd_diff)
    _, _ -> Ok("")
  }
}

fn fake_file_at_tag(
  tag: String,
  path: String,
) -> Result(Option(String), GitError) {
  case tag, path {
    "2.4.1", "src/old.gleam" -> Ok(Some(old_code_source))
    _, _ -> Ok(None)
  }
}

/// A heading with a "code at an older release" badge that links to
/// `target` (a path and an optional anchor) at the tag 2.4.1.
pub fn old_code_heading(target: String) -> String {
  old_code_heading_with("2.4.1", "2.4.1", "2.4.1", target)
}

/// A heading with a "code at an older release" badge: the link names
/// `link_tag` and `target`, the alt text names `alt_tag`, and the image
/// address holds `image_tag` as it is.
pub fn old_code_heading_with(
  link_tag: String,
  alt_tag: String,
  image_tag: String,
  target: String,
) -> String {
  "### Before <a href=\"https://github.com/TrustBound/dream/blob/"
  <> link_tag
  <> "/"
  <> target
  <> "\"><img align=\"right\" alt=\"Code at "
  <> alt_tag
  <> "\" src=\"https://img.shields.io/badge/%F0%9F%93%9C_code_at-"
  <> image_tag
  <> "-lightgrey.svg?style=flat-square\"></a>"
}

/// A `gleam` block with the `body` lines under `heading_line`. The heading
/// is line 1, the fence line 3, and the `body` lines start at line 4.
pub fn gleam_document(
  heading_line: String,
  body: List(String),
) -> List(String) {
  list.flatten([[heading_line, "", "```gleam"], body, ["```"]])
}

/// A heading with a badge that links to `target` (a path and an optional
/// anchor) at the tag 3.0.0.
pub fn heading(target: String) -> String {
  "### Example <a href=\"https://github.com/TrustBound/dream/blob/3.0.0/"
  <> target
  <> badge_end
}

fn guide_source() -> String {
  document([
    "# Example guide",
    "",
    heading(snippet_path <> "#L7-L9"),
    "",
    "```gleam",
    "pub fn main() {",
    "  io.println(\"hi\")",
    "}",
    "```",
    "",
    "## Café au lait",
  ])
}

/// A README example heading: the tested snippet badge that links to
/// `snippet_target`, then the guide badge that links to `guide_target`
/// (a path and an anchor), both at the tag 3.0.0.
pub fn readme_heading(snippet_target: String, guide_target: String) -> String {
  heading(snippet_target)
  <> " <a href=\"https://github.com/TrustBound/dream/blob/3.0.0/"
  <> guide_target
  <> guide_badge_end
}

/// A README with one example under `heading_line`. The heading is line 1
/// and the fence line 3.
pub fn readme_document(heading_line: String) -> List(String) {
  list.flatten([[heading_line, "", "```gleam"], main_function(), ["```"]])
}

/// Checks the lines as the root README with the fake context.
pub fn check_readme(lines: List(String)) -> Report {
  check.check_readme("README.md", document(lines), context())
}

/// A heading with a diff badge that links to the compare view `range`, at
/// the anchor of `path`.
pub fn diff_heading(range: String, path: String) -> String {
  "### Change <a href=\"https://github.com/TrustBound/dream/compare/"
  <> range
  <> "#diff-"
  <> check.path_digest(path)
  <> diff_badge_end
}

/// A diff block under `heading_line`. The heading is line 1, the fence
/// line 3, and the `body` lines start at line 4.
pub fn diff_document(heading_line: String, body: List(String)) -> List(String) {
  list.flatten([[heading_line, "", "```diff"], body, ["```"]])
}

pub fn diff_file_header(path: String) -> List(String) {
  ["--- a/" <> path, "+++ b/" <> path]
}

pub fn document(lines: List(String)) -> String {
  string.join(lines, "\n") <> "\n"
}

/// Checks the lines as the Markdown document `doc.md` with the fake
/// context.
pub fn check(lines: List(String)) -> Report {
  check.check_markdown("doc.md", document(lines), context())
}

/// Checks a diff block with a badge for 2.4.1...3.0.0 and the anchor of
/// `diff_path`.
pub fn diff_report(body: List(String)) -> Report {
  check(diff_document(diff_heading("2.4.1...3.0.0", diff_path), body))
}

pub fn main_function() -> List(String) {
  ["pub fn main() {", "  io.println(\"hi\")", "}"]
}
