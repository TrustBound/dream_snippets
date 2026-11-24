# Show an API change in an upgrade guide

When you change a public function, the people who upgrade need to see what their code looked like before and what it looks like now. The new code is easy: it's a tested snippet like any other. The old code is the problem. It doesn't compile against the new version, so no test can run it, and an untested "before" block is exactly the kind of example that drifts. dream_snippets proves old code against git instead: a diff block must be a part of the real `git diff` since a release tag, and a block of code at an older release must be the exact text of a file at that tag. This guide walks you through an upgrade guide that uses both.

## Table of Contents

- [What you'll build](#what-youll-build)
- [Before you start](#before-you-start)
- [Which block to use](#which-block-to-use)
- [Step 1: Show the old code at its release](#step-1-show-the-old-code-at-its-release)
- [Step 2: Show the new code next to it](#step-2-show-the-new-code-next-to-it)
- [Step 3: Show the change as a diff](#step-3-show-the-change-as-a-diff)
- [Step 4: Run the check](#step-4-run-the-check)
- [Step 5: Run it in CI with the tags](#step-5-run-it-in-ci-with-the-tags)
- [When the check fails](#when-the-check-fails)
- [Test your code](#test-your-code)
- [Common pitfalls](#common-pitfalls)
- [Where to go next](#where-to-go-next)

## What you'll build

The example project is `my_app`. In `0.1.0`, `greeting` takes a name. In `0.2.0`, it also takes a `Style`. In this guide you'll write `docs/guides/upgrading.md` for `0.2.0` with:

- The old call, proven against the file at the tag `0.1.0`.
- The new call, as a tested snippet.
- The change of the signature, as a diff block proven against `git diff 0.1.0`.

## Before you start

You need the package as a dev dependency:

```sh
gleam add --dev dream_snippets
```

You also need a git tag for each release, named exactly as the version in `gleam.toml`. The check reads the old code from that tag, so `0.1.0` must be a tag in your clone. You tag your own release commit, so this block is an illustration:

```sh illustration
git tag 0.1.0
git push origin 0.1.0
```

A tag such as `v0.1.0` doesn't work: the check compares the tag with the versions in `gleam.toml`, and every badge link uses the bare version. Versions follow semver order, so a pre-release comes before its release: code at `0.2.0-rc.1` is code at an older release for `0.2.0`.

For this guide, `gleam.toml` already says `version = "0.2.0"`, and the working tree holds the new code. The new tag doesn't exist yet. It doesn't need to, because the check compares the old tag with your working tree.

## Which block to use

| Your situation | Use | Why |
|:---|:---|:---|
| The reader needs the old call to find it in their own code | Code at an older release | The block shows the old code as the reader wrote it, proven by `git show <tag>:<path>`. |
| The reader needs the new call | A tested snippet | It compiles and runs today, so a test proves it. |
| The reader needs to see exactly what changed in a signature or a type | A diff block | The block is lines of `git diff <tag> -- <path>`, so it can't show a change that didn't happen. |

Use code at an older release only in a guide (a `.md` file under a `guides` directory) or in release notes. The README, the changelog and doc comments show only code of the current version.

## Step 1: Show the old code at its release

At `0.1.0`, the project had this snippet, `test/snippets/guide_upgrading_greet_lucy.gleam`, and its line 4 is the call your readers have in their code. The block shows it with the line numbers that GitHub shows, so it's an illustration:

```text illustration
1  import my_app
2
3  pub fn greet_lucy() -> String {
4    my_app.greeting("Lucy")
5  }
```

To find old lines, ask git for the file at the tag with `git show 0.1.0:test/snippets/guide_upgrading_greet_lucy.gleam`. When you don't know which file, search the old release with `git grep 'greeting(' 0.1.0 -- .`.

Give the block a heading with the code at an older release badge. The link is a `blob` link at the old tag, with the line range of the old code:

```markdown
### Before: greet Lucy <a href="https://github.com/me/my_app/blob/0.1.0/test/snippets/guide_upgrading_greet_lucy.gleam#L4"><img align="right" alt="Code at 0.1.0" src="https://img.shields.io/badge/%F0%9F%93%9C_code_at-0.1.0-lightgrey.svg?style=flat-square"></a>
```

Under it goes a ```` ```gleam ```` fence with the one line `  my_app.greeting("Lucy")`, with its two spaces of indent. The check reads the file with `git show 0.1.0:<path>`, takes line 4, and compares it with the block byte for byte.

The link, the alt text and the image address all name the same tag. In the image address, shields.io needs each `-` of the tag written as `--` and each `_` as `__`, so a tag `0.1.0-rc.1` is `0.1.0--rc.1` there. The heading has no other badge. The old file can be any file at the tag, not only a snippet: `src/my_app.gleam#L1-L3` would show the old function itself.

## Step 2: Show the new code next to it

The new code is a tested snippet in the working tree, so it gets the tested snippet badge at the current version:

```markdown
### After: greet Lucy <a href="https://github.com/me/my_app/blob/0.2.0/test/snippets/guide_upgrading_greet_lucy.gleam#L4"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
```

Its block holds `  my_app.greeting("Lucy", Formal)`, line 4 of the snippet as it is now. The same path at two tags is the normal case: the snippet changed with the release, and each block points at its own version of it. The snippet keeps its test, which asserts what the new call returns.

## Step 3: Show the change as a diff

A diff block shows the change itself. Here's the real output of `git diff 0.1.0 -- src/my_app.gleam`, the diff from `0.1.0` to the working tree. The test of this guide runs git in the example project and compares its output with this file:

### The diff of the example project <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_upgrade_guides_git_diff.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
diff --git a/src/my_app.gleam b/src/my_app.gleam
index 3a8f4d4..d72828d 100644
--- a/src/my_app.gleam
+++ b/src/my_app.gleam
@@ -1,3 +1,11 @@
-pub fn greeting(name: String) -> String {
-  "Hello, " <> name <> "!"
+pub fn greeting(name: String, style: Style) -> String {
+  case style {
+    Casual -> "Hi, " <> name <> "!"
+    Formal -> "Hello, " <> name <> "."
+  }
+}
+
+pub type Style {
+  Casual
+  Formal
 }
```

A diff block is an excerpt of that. It starts with the `--- a/<path>` and `+++ b/<path>` lines, then holds lines of the diff with their `-`, `+` or space prefix. Lines with no `@@` header between them must come from one hunk, in order, with nothing left out between them. To skip to a later hunk, put that hunk's `@@` line in the block. The guide of the example project shows the first four changed lines. Its diff badge links to the repository of the example project, which this package can't check, so the example is an illustration:

````text illustration
#### The new signature <a href="https://github.com/me/my_app/compare/0.1.0...0.2.0#diff-dc300fec45bded4a328557d8cdb35d83594380337bd562985800e8086dc62ebd"><img align="right" alt="Tested diff" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-diff-lightgreen.svg?style=flat-square"></a>

```diff
--- a/src/my_app.gleam
+++ b/src/my_app.gleam
-pub fn greeting(name: String) -> String {
-  "Hello, " <> name <> "!"
+pub fn greeting(name: String, style: Style) -> String {
+  case style {
```
````

The badge links to GitHub's compare view, from the old tag to the version in `gleam.toml`. The anchor `#diff-<digest>` is GitHub's own anchor for one file in that view: the SHA-256 hex digest of the path. Work it out with a shell, `printf '%s' src/my_app.gleam | shasum -a 256`, or with `check.path_digest`. For `src/my_app.gleam`, the test of this guide asserts that it's `dc300fec45bded4a328557d8cdb35d83594380337bd562985800e8086dc62ebd`.

## Step 4: Run the check

Run `gleam run -m dream_snippets`:

### The summary of the upgrade guide <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_upgrade_guides_passes.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
2 blocks and 1 diff block checked in 2 files, 0 problems; 0 file blocks, 0 command blocks and 0 output blocks checked; 0 illustration blocks
```

Two Gleam blocks passed: the old call against `0.1.0`, and the new call against the working tree. The diff block passed against the real diff. Diff blocks have their own count in the summary.

## Step 5: Run it in CI with the tags

`actions/checkout` makes a shallow clone with no tags, and then the check can't find `0.1.0`. Check out the whole history with `fetch-depth: 0`, as the workflow in [Getting started](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/getting-started.md#step-7-run-the-check-in-ci) does.

## When the check fails

Each of these is the real output for the example project with one thing wrong. For the old code and the diff, the line is the opening fence of the block, and a wrong diff line is reported at that line.

**The old tag isn't in the clone.** Both blocks that need it fail:

### The messages of a missing tag <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_upgrade_guides_no_tag.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
docs/guides/upgrading.md:7: the tag 0.1.0 is not in this clone; fetch the tags with "git fetch --tags" (a shallow clone has none)
docs/guides/upgrading.md:19: the tag 0.1.0 is not in this clone; fetch the tags with "git fetch --tags" (a shallow clone has none)
2 blocks and 1 diff block checked in 2 files, 2 problems; 0 file blocks, 0 command blocks and 0 output blocks checked; 0 illustration blocks
```

Run `git fetch --tags` locally, and use `fetch-depth: 0` in CI. If the tag never existed, tag the release commit.

**The old code names the current version.** Code at `0.2.0` is current code, so it needs a tested snippet instead:

### The message of old code at the current version <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_upgrade_guides_current_version.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
docs/guides/upgrading.md:7: the tag 0.2.0 is not a release before 0.2.0, the version in gleam.toml, so use the tested snippet badge for this code
2 blocks and 1 diff block checked in 2 files, 1 problem; 0 file blocks, 0 command blocks and 0 output blocks checked; 0 illustration blocks
```

**A diff line isn't in the real diff.** Here the block says `style: Style, loud: Bool`, a change that never happened:

### The message of a diff line that is not in the diff <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_upgrade_guides_diff_line.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
docs/guides/upgrading.md:24: this line is not in "git diff 0.1.0 -- src/my_app.gleam" at this place; a diff block shows lines of the real diff, in order and contiguous within a hunk
2 blocks and 1 diff block checked in 2 files, 1 problem; 0 file blocks, 0 command blocks and 0 output blocks checked; 0 illustration blocks
```

Copy the lines from `git diff <tag> -- <path>` again. A line also fails when it's real but out of place, for example after a line that the block skipped.

**The anchor names another file.** The message gives you the right one:

### The message of the anchor of another file <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_upgrade_guides_anchor.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
docs/guides/upgrading.md:19: the compare link anchor is not the one for src/my_app.gleam; use #diff-dc300fec45bded4a328557d8cdb35d83594380337bd562985800e8086dc62ebd
2 blocks and 1 diff block checked in 2 files, 1 problem; 0 file blocks, 0 command blocks and 0 output blocks checked; 0 illustration blocks
```

**Old code in the README.** The README shows only what works now:

### The message of old code in the README <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_upgrade_guides_readme.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
README.md:5: the code at an older release badge is only allowed in the guides under docs/guides and in release notes, because the README, the changelog and doc comments show only code of the current version
3 blocks and 1 diff block checked in 3 files, 1 problem; 0 file blocks, 0 command blocks and 0 output blocks checked; 0 illustration blocks
```

[Fix a failed check](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/fixing-check-failures.md#diff-blocks) lists the rest: a malformed badge, a missing file header, a file with no changes, an unsafe tag, a file that doesn't exist at the tag, and more.

## Test your code

The old code and the diff need no test of their own: git is their proof, and the check runs it. The new code is a snippet, so give it a test that asserts what the new call returns, as for any other snippet.

What's worth adding is the check itself in your test run, so `gleam test` fails on a stale upgrade guide before CI does. This test passes when the check prints only its summary line:

### Fail the tests when the docs check fails <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/guide_use_from_gleam_docs_test.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_snippets

pub fn docs_test() {
  let output = dream_snippets.output(dream_snippets.check_project("."))
  let assert [_summary] = output.standard_output
}
```

When it fails, the failed `let assert` shows the lines it got, which are the problems. [Use it from Gleam](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/use-from-gleam.md#step-2-fail-your-tests-when-the-docs-are-wrong) explains it.

## Common pitfalls

**Tags with a `v`.** *Symptom:* every badge fails with a wrong tag, or old code fails with `is not a release before`. *Fix:* the check uses the bare version, `0.1.0`, for every tag. Add tags with the bare version for the releases your docs name.

**A diff block that skips lines.** *Symptom:* `this line is not in "git diff ..." at this place`, although the line is in the diff. *Fix:* lines between two `@@` headers must follow each other in the real diff. Keep the lines in between, or start a new run with the `@@` header of its hunk.

**A diff block in a guide after the next version bump.** *Symptom:* when `gleam.toml` moves on to `0.3.0`, the block in a guide fails with `the compare link ends at the tag 0.2.0, but this file must use the new tag 0.3.0 (the docs of my_app use the version in gleam.toml)`. *Fix:* in a guide, the new tag of a diff badge is the version in `gleam.toml`, and the check compares the old tag with the working tree. When the release ships, either move the link to `0.1.0...0.3.0` and copy the lines of the new diff, or replace the diff block with old code and new code blocks. Code at an older release stays valid at any later version. The release notes of `0.2.0` and the `## [0.2.0]` section of the changelog don't have this problem: they belong to `0.2.0`, so after the bump their diff blocks are compared with `git diff 0.1.0 0.2.0`, and their tested snippets with the files at the tag `0.2.0`. A diff that must stay is safe there.

**A shallow clone.** *Symptom:* `is not in this clone` in CI only. *Fix:* `fetch-depth: 0` in `actions/checkout`.

## Where to go next

- [Tested code blocks](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md): every badge form, ready to copy.
- [Release notes template](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/release-notes-template.md): release notes can show code at an older release too, in their `Upgrading` section.
- [Fix a failed check](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/fixing-check-failures.md): every message, with the fix.
- [API reference on HexDocs](https://hexdocs.pm/dream_snippets/dream_snippets/check.html): `path_digest`, `parse_old_code_heading`, `parse_compare_link` and `parse_hunks`.
