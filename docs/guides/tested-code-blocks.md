# Tested code blocks

The check wants each badge in one exact form, and a message sends you here when a heading doesn't match it. The four forms are right below, ready to copy. After them, this guide walks through the places a tested block can go: a guide, an excerpt of a longer file, a doc comment and the README. It also shows how to keep Gleam code out of the fences the check can't prove.

## Table of Contents

- [Copy a badge](#copy-a-badge)
- [What you'll build](#what-youll-build)
- [Before you start](#before-you-start)
- [Which badge to use](#which-badge-to-use)
- [Step 1: Show a whole file](#step-1-show-a-whole-file)
- [Step 2: Show part of a file with a line range](#step-2-show-part-of-a-file-with-a-line-range)
- [Step 3: Show an example in a doc comment](#step-3-show-an-example-in-a-doc-comment)
- [Step 4: Add an example to the README](#step-4-add-an-example-to-the-readme)
- [Step 5: Keep Gleam code out of other fences](#step-5-keep-gleam-code-out-of-other-fences)
- [When the check fails](#when-the-check-fails)
- [Test your code](#test-your-code)
- [Common pitfalls](#common-pitfalls)
- [Where to go next](#where-to-go-next)

## Copy a badge

Replace `<owner>`, `<repo>`, `<version>`, `<path>` and the heading text. Keep everything else exactly as it is. `<owner>` and `<repo>` are the `user` and `repo` of `repository` in `gleam.toml`, and `<version>` is its `version`. In release notes and in a `## [<version>]` changelog section, `<version>` is the release of the notes or the section instead, so the notes of `0.1.0` keep linking at `0.1.0` after the next version bump. Each badge goes at the end of the heading, after one space.

**The tested snippet badge**, for a ```` ```gleam ```` block. `<path>` is the snippet file from the project root. Add `#L<start>-L<end>` to show only those lines:

```markdown
### Encode a user <a href="https://github.com/<owner>/<repo>/blob/<version>/<path>"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
```

**The tested snippet badge and the guide badge**, for an example in the root `README.md`. The guide badge comes second, after one space. `<guide>` is a `.md` file under `docs/guides`, and `<anchor>` is the anchor of the guide heading that shows the same snippet, so it ends with a hyphen:

```markdown
### Encode a user <a href="https://github.com/<owner>/<repo>/blob/<version>/<path>"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a> <a href="https://github.com/<owner>/<repo>/blob/<version>/<guide>#<anchor>"><img align="right" alt="Guide" src="https://img.shields.io/badge/%F0%9F%93%96_read-guide-blue.svg?style=flat-square"></a>
```

**The tested diff badge**, for a ```` ```diff ```` block. `<old tag>` is an earlier release tag, the new tag is `<version>`, and `<digest>` is the SHA-256 hex digest of the path of the file in the block (`printf '%s' <path> | shasum -a 256`):

```markdown
#### Rename the encoder <a href="https://github.com/<owner>/<repo>/compare/<old tag>...<version>#diff-<digest>"><img align="right" alt="Tested diff" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-diff-lightgreen.svg?style=flat-square"></a>
```

**The code at an older release badge**, for a ```` ```gleam ```` block of old code in a guide or in release notes. All three places name the same `<old tag>`. In the image address, write each `-` of the tag as `--` and each `_` as `__`, so `2.0.0-rc.1` is `2.0.0--rc.1` there. The heading has no other badge:

```markdown
### Before: encode a user <a href="https://github.com/<owner>/<repo>/blob/<old tag>/<path>#L12-L18"><img align="right" alt="Code at <old tag>" src="https://img.shields.io/badge/%F0%9F%93%9C_code_at-<old tag>-lightgrey.svg?style=flat-square"></a>
```

[Show an API change in an upgrade guide](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/upgrade-guides.md) explains the last two forms step by step.

## What you'll build

In this guide you'll:

- Show a whole snippet file, and an excerpt of one with a line range.
- Put a tested example in a doc comment, and check it.
- Add an example to the README with a guide badge, and work out the anchor it links to.
- Show command output and example documents without tripping the check.

## Before you start

You need the package as a dev dependency and a project with a GitHub `repository` in `gleam.toml`. [Getting started](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/getting-started.md) sets that up and shows one tested block from start to finish.

```sh
gleam add --dev dream_snippets
```

The examples below use the project `me/my_app` at version `0.1.0`. Run the check from the project root with `gleam run -m dream_snippets`.

## Which badge to use

| Your situation | Use | Why |
|:---|:---|:---|
| Gleam code that works with the current version | The tested snippet badge | The block is a copy of a snippet file that your tests run. |
| The same example in the root README | The tested snippet badge, then the guide badge | The README links each example to the guide section that explains it. |
| A change between two releases, in an upgrade guide | The tested diff badge | Old code doesn't compile any more. The block is a part of the real `git diff` instead. |
| Old code next to the new code, in a guide or in release notes | The code at an older release badge | The block is a copy of a file at an older release tag, read from git. |
| Command output, shell commands, TOML, YAML | No badge, in a `text`, `sh`, `toml` or `yaml` fence | The check doesn't prove these. It only makes sure that they hold no Gleam code. |

## Step 1: Show a whole file

The simplest block is a whole snippet file. Put the tested snippet badge at the end of the heading, then the code in a `gleam` fence directly below, with at most one blank line between:

```markdown
### Greet a user <a href="https://github.com/me/my_app/blob/0.1.0/test/snippets/guide_getting_started_greeting.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
```

The check turns the link into a local path, reads `test/snippets/guide_getting_started_greeting.gleam` from your working tree, and compares it with the block byte for byte. In the release notes or changelog section of an older release, it reads the file at the tag of that release instead. The block may leave out the `////` comment at the top of the file and the blank line after it. Every other line must be there, with the same indent.

Use a full GitHub address, not a relative path. HexDocs and Hex show your docs without your repository, and a full address at a fixed tag still opens the file the docs were checked against.

## Step 2: Show part of a file with a line range

A snippet often needs more than the docs want to show: imports, a helper, a second function. End the link with a GitHub line range, and the block shows only those lines. Here's a snippet with two functions, and the block shows lines 13 to 16, the second function with its doc comment:

### Tell whether a guide has an anchor <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/guide_tested_code_blocks_anchor.gleam#L13-L16"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
/// Tells whether a guide has a heading with the anchor.
pub fn has_anchor(guide: String, anchor: String) -> Bool {
  list.contains(check.heading_anchors(guide), anchor)
}
```

The link ends in `#L13-L16`. `#L14` alone names one line. The lines keep their indent, so an excerpt from inside a function starts with spaces. The range must be inside the file: a range past the last line or one that ends before it starts is a problem, and so is an anchor in any other form.

A line range ties the block to line numbers, so a new import at the top of the snippet moves every range below it. The check catches that, because the block no longer matches. Fix the numbers in the link, not the code in the block.

## Step 3: Show an example in a doc comment

Doc comments in `src/` are docs too, and HexDocs shows them on the first page a reader opens. The check reads each run of `///` or `////` lines as a Markdown document, so an example there needs the same heading and badge, inside the comment. Here's a function whose doc comment shows a tested example:

### A doc comment with a tested example <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/guide_tested_code_blocks_doc_comment.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import gleam/string

/// Builds a greeting for a name.
///
/// ## Examples
///
/// ### Greet Lucy <a href="https://github.com/me/my_app/blob/0.1.0/test/snippets/guide_tested_code_blocks_greet_lucy.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import snippets/guide_tested_code_blocks_doc_comment as greeting
///
/// pub fn greet_lucy() -> String {
///   // Returns "Hello, Lucy!"
///   greeting.greeting("lucy")
/// }
/// ```
pub fn greeting(name: String) -> String {
  "Hello, " <> string.capitalise(name) <> "!"
}
```

And here's the snippet file the badge links to. The check removes the `/// ` prefix from each line before it compares, so the block in the comment is the same as this file without its module comment:

### The example that the doc comment shows <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/guide_tested_code_blocks_greet_lucy.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import snippets/guide_tested_code_blocks_doc_comment as greeting

pub fn greet_lucy() -> String {
  // Returns "Hello, Lucy!"
  greeting.greeting("lucy")
}
```

A `// Returns ...` comment is a good habit for doc examples: HexDocs shows the result next to the call, and the test of the snippet asserts that exact value, so the comment can't drift either. The doc comments of this package follow that form.

A few details:

- The comment prefix is `/// `, `//// `, or `///` and `////` alone on an empty comment line. Doc comments indented inside a block are checked too.
- A doc comment can't hold a guide badge. Only README examples have one.
- With no settings, the check reads every `.gleam` file under `src/`. The `gleam_source` setting changes that.

## Step 4: Add an example to the README

An example in the root `README.md` carries two badges: the tested snippet badge, then one space and the guide badge. Both images float right, so the guide badge shows to the left of the tested snippet badge. The guide badge sends a reader from the short example to the section that explains it:

```markdown
### Greet a user <a href="https://github.com/me/my_app/blob/0.1.0/test/snippets/guide_getting_started_greeting.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a> <a href="https://github.com/me/my_app/blob/0.1.0/docs/guides/getting-started.md#greet-a-user-"><img align="right" alt="Guide" src="https://img.shields.io/badge/%F0%9F%93%96_read-guide-blue.svg?style=flat-square"></a>
```

The check wants these things of the guide badge:

- The link is a `blob` link of the same repository, at the tag of the `version` in `gleam.toml`.
- The path is a `.md` file under a guide directory. The default directory is `docs/guides`, and the `guides` setting changes it.
- The guide file exists.
- The link ends with `#<anchor>`, and the anchor is the anchor of a heading in the guide.
- The guide has a tested snippet badge that links to the same snippet file. Its line range can be different.

Only the root README has guide badges. A heading in a guide, the changelog, release notes or a doc comment has only the tested snippet badge, and a `diff` heading or a heading of code at an older release has none.

### Work out the anchor

The anchor is the one GitHub makes for the heading:

1. Remove the spaces at the start and the end of the heading text.
2. Remove inline HTML tags, such as a badge link, and Markdown marks. The spaces around a tag stay. A link keeps its text, and a code span keeps its text.
3. Change the text to lowercase.
4. Remove each character that is not a letter, a digit, a space, a hyphen or an underscore.
5. Change each space to a hyphen. The spaces aren't removed again after step 2.

So a guide heading with a badge keeps the space before the badge, and its anchor ends with a hyphen: `### Greet a user <a ...>` gets `greet-a-user-`. A heading with two badges, each after a space, gets two hyphens. When two headings get the same anchor, the second one gets `-1` at the end, and the third one gets `-2`.

If you'd rather not count hyphens, ask the check. `check.heading_anchors` gives the anchors of a document in order, with the same rules, and the snippet from [Step 2](#step-2-show-part-of-a-file-with-a-line-range) wraps it:

### List the anchors of a guide <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/guide_tested_code_blocks_anchor.gleam#L8-L11"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
/// The anchors of the headings of a guide, as GitHub makes them.
pub fn guide_anchors(guide: String) -> List(String) {
  check.heading_anchors(guide)
}
```

For a guide with the headings `# Greeting users`, `## What's New`, ``### The `greeting` function``, `### Greet a user` with one badge, `### Greet a user` with two badges, and `## Usage` two times, it returns:

```text
["greeting-users", "whats-new", "the-greeting-function", "greet-a-user-", "greet-a-user--", "usage", "usage-1"]
```

Leave out the last hyphen and the check names the anchor it couldn't find:

```text
README.md:3: the guide badge links to the anchor #greet-a-user, but docs/guides/getting-started.md has no heading with that anchor
2 blocks and 0 diff blocks checked in 3 files, 1 problem
```

## Step 5: Keep Gleam code out of other fences

A block the check can't see can't be proven, so Gleam code must not hide in a fence with another language or none. A line in a `text`, `sh` or unlabelled fence counts as Gleam when it has one of these forms, which no other common language of the docs has:

- `import a/b` (a module path with a `/`) or `import a.{...}`
- `fn name(` or `pub fn name(`
- `pub type Name`, `pub opaque type Name` or `type Name` with no `=`
- `use x <- ...`
- `let assert ...`
- a pipe into a module function, such as `|> list.map(`

A `text` fence in `docs/guides/usage.md` that holds `import my_app/greeting` on line 4 fails:

```text
docs/guides/usage.md:4: this line looks like Gleam code in a text code fence; put Gleam code in a gleam block with the tested snippet badge
0 blocks and 0 diff blocks checked in 2 files, 1 problem
```

Output, shell commands and config files are fine in their own fences. A `diff` fence is its own kind of block, with its own badge.

A ```` ```markdown ```` fence holds an example document, like the headings in this guide. The check looks inside it: its fences are checked like the fences of any other document, and its other lines must not look like Gleam code. So an example document can show headings and badges freely, but a ```` ```gleam ```` block inside it needs a real badge to a real snippet, the same as anywhere else. Show headings in the `markdown` fence and the code in its own tested block, as this guide does.

## When the check fails

Each problem is one line, `file:line: reason`. For a code block and its badge, the line is the opening fence of the block. For a guide badge, it's the heading. The most common ones while you write:

| You see | It means | Fix |
|:---|:---|:---|
| `has no heading with the tested snippet badge directly above it` | No heading, a heading without the badge, or two blank lines before the fence | Add the heading with the badge, one blank line at most |
| `the tested snippet badge is not in the exact format` | A changed character in the badge | Copy it from [Copy a badge](#copy-a-badge) |
| `the badge link uses the tag 0.1.0, but this file must link at the tag 0.2.0` | The version in `gleam.toml` changed | Change the tag in every badge link of the guides, the README and the doc comments. Release notes and changelog sections keep their own release. |
| `the code block is not the same as ...; the first difference is at line 9` | The snippet changed, or the block was edited | Copy the file or the line range into the block again |
| `the line range ends at line 20, but the file has 16 lines` | The snippet got shorter | Fix the numbers in the link |

[Fix a failed check](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/fixing-check-failures.md) has every message, with what it means and the fix.

## Test your code

The check proves that the docs show the snippet. Your tests prove that the snippet works. Give each snippet a test that runs it and asserts the exact value its docs show. The tests of this guide do that: `has_anchor(guide, "greet-a-user-")` returns `True` and `has_anchor(guide, "greet-a-user")` returns `False` for the example guide, and `greet_lucy()` returns `"Hello, Lucy!"`.

To check a doc comment from a test, without a whole project, call `check.check_gleam_source` with a `CheckContext`. [Use it from Gleam](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/use-from-gleam.md) shows how to build one. For the doc comment of [Step 3](#step-3-show-an-example-in-a-doc-comment), it returns `Report(blocks_checked: 1, diff_blocks_checked: 0, problems: [])`.

## Common pitfalls

**A badge typed from memory.** *Symptom:* `not in the exact format`, and the badge looks right. *Fix:* the check compares the whole badge text, including `align="right"` and `style=flat-square`. Copy it from [Copy a badge](#copy-a-badge).

**A guide badge anchor without the last hyphen.** *Symptom:* `has no heading with that anchor`. *Fix:* a guide heading with a badge ends with a space before the badge, so its anchor ends with `-`. Use `check.heading_anchors` when you're not sure.

**A guide badge to a guide that shows another snippet.** *Symptom:* `has no tested snippet badge that links to ...`. *Fix:* the guide section must show the same snippet file as the README example. Show the snippet in the guide too, or link the README example to the guide that shows it.

**A guide badge outside the README.** *Symptom:* `this heading has a guide badge, but only README example headings have one`. *Fix:* copy headings from a guide into the README, not the other way round. Remove the guide badge from the guide heading.

**A relative link in a badge.** *Symptom:* `does not point at a file in https://github.com/me/my_app`. *Fix:* use the full GitHub address at the release tag.

## Where to go next

- [Getting started](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/getting-started.md): set up the check in a project from nothing.
- [Fix a failed check](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/fixing-check-failures.md): every message, what it means and the fix.
- [Show an API change in an upgrade guide](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/upgrade-guides.md): diff blocks and code at an older release.
- [Settings and checks reference](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/reference.md): the `guides`, `markdown` and `gleam_source` settings, and the full list of checks.
- [API reference on HexDocs](https://hexdocs.pm/dream_snippets/dream_snippets/check.html): `heading_anchors`, `heading_slug` and the other rules.
