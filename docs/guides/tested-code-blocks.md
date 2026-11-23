# Tested code blocks

The check wants each badge in one exact form, and a message sends you here when a heading doesn't match it. The four forms are right below, ready to copy. After them, this guide walks through the places a tested block can go: a guide, an excerpt of a longer file, a doc comment and the README. Then it shows the proof of every other kind of block: a config file, a command, output, packages to add, and an illustration that nothing proves. Every fenced code block in the checked docs has a proof, and none is skipped in silence.

## Table of Contents

- [Copy a badge](#copy-a-badge)
- [What you'll build](#what-youll-build)
- [Before you start](#before-you-start)
- [Which proof to use](#which-proof-to-use)
- [Step 1: Show a whole file](#step-1-show-a-whole-file)
- [Step 2: Show part of a file with a line range](#step-2-show-part-of-a-file-with-a-line-range)
- [Step 3: Show an example in a doc comment](#step-3-show-an-example-in-a-doc-comment)
- [Step 4: Add an example to the README](#step-4-add-an-example-to-the-readme)
- [Step 5: Show a file that the tests or CI use](#step-5-show-a-file-that-the-tests-or-ci-use)
- [Step 6: Show a command](#step-6-show-a-command)
- [Step 7: Show output](#step-7-show-output)
- [Step 8: Show packages to add](#step-8-show-packages-to-add)
- [Step 9: Keep Gleam code out of illustrations](#step-9-keep-gleam-code-out-of-illustrations)
- [When the check fails](#when-the-check-fails)
- [Test your code](#test-your-code)
- [Common pitfalls](#common-pitfalls)
- [Where to go next](#where-to-go-next)

## Copy a badge

Replace `<owner>`, `<repo>`, `<version>`, `<path>` and the heading text. Keep everything else exactly as it is. `<owner>` and `<repo>` are the `user` and `repo` of `repository` in `gleam.toml`, and `<version>` is its `version`. In release notes and in a `## [<version>]` changelog section, `<version>` is the release of the notes or the section instead, so the notes of `0.1.0` keep linking at `0.1.0` after the next version bump. Each badge goes at the end of the heading, after one space.

**The tested snippet badge**, for a ```` ```gleam ```` block, and for a file, command or output block. `<path>` is the snippet file, or the file that the block copies, from the project root. Add `#L<start>-L<end>` to show only those lines:

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
- Show a config file, a command and output, each a copy of a file that the tests or CI use.
- Show `gleam add` lines and dependency lines, which need no file.
- Mark a folder tree as an illustration, and keep Gleam code out of it.

## Before you start

You need the package as a dev dependency and a project with a GitHub `repository` in `gleam.toml`. [Getting started](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/getting-started.md) sets that up and shows one tested block from start to finish.

```sh
gleam add --dev dream_snippets
```

The examples below use the project `me/my_app` at version `0.1.0`. Run the check from the project root with `gleam run -m dream_snippets`.

## Which proof to use

The language of the fence, the first word after the backticks, sets the kind of the block. Each kind has one proof:

| The block | Its kind | The proof |
|:---|:---|:---|
| Gleam code that works with the current version, in a `gleam` fence | Gleam block | The tested snippet badge: a copy of a snippet file that your tests run. In the root README, the guide badge too. |
| A change between two releases, in a `diff` fence | Diff block | The tested diff badge: a part of the real `git diff`. |
| Old code next to the new code, in a guide or in release notes | Gleam block | The code at an older release badge: a copy of a file at an older release tag, read from git. |
| A config file, a Dockerfile, SQL, YAML, any other language | File block | The tested snippet badge: a copy of a file that the tests or CI use. A `toml` block of only dependency lines of your package needs no badge ([Step 8](#step-8-show-packages-to-add)). |
| A command, in a `bash`, `sh`, `shell` or `console` fence | Command block | The tested snippet badge: a copy of a script that CI or a test runs. A block of only `gleam add` and `gleam deps update` lines needs no badge ([Step 8](#step-8-show-packages-to-add)). |
| What a program prints or returns, in a `text` fence | Output block | The tested snippet badge: a copy of an output file that a test compares with the real output. |
| An example document, in a `markdown` or `md` fence | Example document | The fences inside it are checked like any other fence ([Step 9](#step-9-keep-gleam-code-out-of-illustrations)). |
| A folder tree, a diagram, a placeholder form | Illustration | Nothing proves it. Write `illustration` after the language, as in ```` ```text illustration ````. The summary counts it, and it must not hold Gleam code. |
| A fence with no language | None | Always a problem. Name the language. |

The check can't see whether a test or CI uses a file. So the project lists the files and directories that they use in the `tested_files` setting, and a file, command or output block can link only to a file in that list or under it. The default is `["test", ".github"]`. [Settings and checks reference](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/reference.md#settings) has the details.

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

### The anchors of the example guide <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_tested_code_blocks_anchors.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
["greeting-users", "whats-new", "the-greeting-function", "greet-a-user-", "greet-a-user--", "usage", "usage-1"]
```

Leave out the last hyphen and the check names the anchor it couldn't find:

### The message of an anchor without the last hyphen <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_tested_code_blocks_anchor_missing.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
README.md:3: the guide badge links to the anchor #greet-a-user, but docs/guides/getting-started.md has no heading with that anchor
2 blocks and 0 diff blocks checked in 3 files, 1 problem; 0 file blocks, 0 command blocks and 0 output blocks checked; 0 illustration blocks
```

## Step 5: Show a file that the tests or CI use

A block of a config file, a Dockerfile, SQL or YAML is a file block. It's a copy of a real file that the tests or CI use, such as the Dockerfile that CI builds, a migration that the tests apply, or the `gleam.toml` of a tested example project. It takes the same heading and badge as a Gleam snippet, and the same line ranges. Here's the `gleam.toml` of the example project of the guides, which the tests of the guides read:

### The gleam.toml of the example project <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/fixtures/my_app/gleam.toml"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```toml
name = "my_app"
version = "0.1.0"
repository = { type = "github", user = "me", repo = "my_app" }
```

The check compares the block with the file byte for byte, as it does for a Gleam block. The file must be one of the `tested_files` paths of the project, or under one of them. The default `["test", ".github"]` holds the files of the tests and the workflows of CI. This package also lists the scripts that CI runs, its `Makefile` and its own `gleam.toml`, which every build reads:

### The settings of this package <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/gleam.toml#L31-L33"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```toml
[tools.dream_snippets]
markdown = ["README.md", "SECURITY.md", "CONTRIBUTING.md", "docs"]
tested_files = ["test", ".github", "scripts", "Makefile", "gleam.toml"]
```

## Step 6: Show a command

A `bash`, `sh`, `shell` or `console` block is a command block. Put the command in a script that CI or a test runs, and link the block to its line. This package keeps the commands that CI runs in `scripts/check.sh`, so the command that runs the check is line 10 of that script:

### Run the check <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/scripts/check.sh#L10"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```sh
gleam run -m dream_snippets
```

When the script changes, the block no longer matches, and the check tells you. A command that no script runs, such as a command that a reader runs one time in their own project, can be an illustration.

## Step 7: Show output

A `text` block is an output block: what a program prints or returns. Put the output in a file, such as `test/outputs/<name>.txt`, and have a test compare the file with the real output. Then link the block to the file. The anchors of [Step 4](#work-out-the-anchor) are in `test/outputs/guide_tested_code_blocks_anchors.txt`, and this helper compares them with the real anchors:

### Compare the real output with the output file <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/guide_tested_code_blocks_output.gleam#L10-L18"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
/// Tells whether the output file holds the anchors of the guide, as
/// `string.inspect` writes them, with a line break at the end.
pub fn anchors_match_output_file(guide: String) -> Bool {
  let real =
    string.inspect(guide_tested_code_blocks_anchor.guide_anchors(guide))
  let shown =
    simplifile.read("test/outputs/guide_tested_code_blocks_anchors.txt")
  shown == Ok(real <> "\n")
}
```

The test of this guide asserts that it returns `True` for the example guide, and `False` for another one. So the output block can't drift: a change of `heading_anchors` fails the test, and a change of the file fails the check. The output blocks of all the guides of this package work this way, and their tests compare the output of the check with a file in `test/outputs/`.

## Step 8: Show packages to add

Two kinds of block need no file, because the check can prove them with `gleam.toml`.

A command block whose lines are each `gleam add` or `gleam deps update` (blank lines are allowed) needs no badge. Each argument is a package name, or `--dev` on a `gleam add` line. Each package is the `name` of your project, or a key of `[dependencies]` or `[dev-dependencies]` in its `gleam.toml`. So a reader adds a package that exists and that your project uses:

```sh
gleam add --dev dream_snippets
```

A `toml` block whose lines are each `[dependencies]`, `[dev-dependencies]` or `<package> = "<requirement>"` needs no badge either, when its first line is one of the two tables. It names only the package of your project, and the requirement is `>= <release> and < <next major>.0.0`, the one that `gleam add` writes for the release of the document. In the release notes of `1.0.0`, and in a guide while `gleam.toml` says `1.0.0`, that's:

```toml
[dev-dependencies]
dream_snippets = ">= 1.0.0 and < 2.0.0"
```

After the next version bump, a guide must show the new release, and the check tells you. The release notes of `1.0.0` keep `1.0.0`. This proves the upgrade and install blocks of the [release notes template](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/release-notes-template.md) with no file. A block with another line, another package or a version in a `gleam add` line needs a file instead.

## Step 9: Keep Gleam code out of illustrations

Some blocks have nothing to be a copy of: a folder tree, a diagram, a placeholder form. Mark such a block as an illustration: write the word `illustration` after the language, with one space:

```text illustration
my_app/
  docs/guides/getting-started.md
  test/outputs/getting_started.txt
```

GitHub and HexDocs read only the first word of the info string, so the block shows as a `text` block. The mark stays in the Markdown source, where `grep -rn 'illustration$'` finds every one. The summary line counts the illustrations, so a reviewer sees how many there are. Use them for what can't be proven, not to skip a proof. A `gleam`, `diff` or `markdown` block is never an illustration.

An illustration must not hold Gleam code, because nothing would prove it. A line counts as Gleam when it has one of these forms, which no other common language of the docs has:

- `import a/b` (a module path with a `/`) or `import a.{...}`
- `fn name(` or `pub fn name(`
- `pub type Name`, `pub opaque type Name` or `type Name` with no `=`
- `use x <- ...`
- `let assert ...`
- a pipe into a module function, such as `|> list.map(`

An illustration in `docs/guides/usage.md` that holds `import my_app/greeting` on line 4 fails:

### The message of Gleam code in an illustration <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_tested_code_blocks_hidden_gleam.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
docs/guides/usage.md:4: this line looks like Gleam code in a text illustration code fence; put Gleam code in a gleam block with the tested snippet badge
0 blocks and 0 diff blocks checked in 2 files, 1 problem; 0 file blocks, 0 command blocks and 0 output blocks checked; 1 illustration block
```

A ```` ```markdown ```` fence holds an example document, like the headings in this guide. The check looks inside it:

- Each fence in it is checked like a fence of any other document, with the same kinds and proofs. A ```` ```gleam ```` block in it needs a real badge to a real snippet, and a `text` block needs an output file.
- Each other line must not look like Gleam code.
- Its headings, links and other prose are not checked, and neither are its badges unless a fence sits under them. An example document of release notes is not checked against the release notes template.

That's sound, because prose proves nothing and claims nothing that a reader runs: every line that a reader could run is in a fence, and every fence is proven. So an example document can show headings and badges freely. Show the headings in the `markdown` fence and the code in its own tested block, as this guide does.

## When the check fails

Each problem is one line, `file:line: reason`. For a code block and its badge, the line is the opening fence of the block. For a guide badge, it's the heading. The most common ones while you write:

| You see | It means | Fix |
|:---|:---|:---|
| `has no heading with the tested snippet badge directly above it` | No heading, a heading without the badge, or two blank lines before the fence | Add the heading with the badge, one blank line at most |
| `the tested snippet badge is not in the exact format` | A changed character in the badge | Copy it from [Copy a badge](#copy-a-badge) |
| `the badge link uses the tag 0.1.0, but this file must link at the tag 0.2.0` | The version in `gleam.toml` changed | Change the tag in every badge link of the guides, the README and the doc comments. Release notes and changelog sections keep their own release. |
| `the code block is not the same as ...; the first difference is at line 9` | The snippet changed, or the block was edited | Copy the file or the line range into the block again |
| `the line range ends at line 20, but the file has 16 lines` | The snippet got shorter | Fix the numbers in the link |
| `this text code block has no heading with the tested snippet badge` | An output block with no proof | Put the output in a file that a test compares, and link to it ([Step 7](#step-7-show-output)) |
| `which is not under a tested_files path` | A file, command or output block links to a file that the project doesn't list as used | Link to a file that the tests or CI use, and list it in `tested_files` |
| `this code fence has no language` | A fence with no language | Name the language, or mark the block as an illustration |

[Fix a failed check](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/fixing-check-failures.md) has every message, with what it means and the fix.

## Test your code

The check proves that the docs show the snippet. Your tests prove that the snippet works. Give each snippet a test that runs it and asserts the exact value its docs show. The tests of this guide do that: `has_anchor(guide, "greet-a-user-")` returns `True` and `has_anchor(guide, "greet-a-user")` returns `False` for the example guide, and `greet_lucy()` returns `"Hello, Lucy!"`.

To check a doc comment from a test, without a whole project, call `check.check_gleam_source` with a `CheckContext`. [Use it from Gleam](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/use-from-gleam.md) shows how to build one. For the doc comment of [Step 3](#step-3-show-an-example-in-a-doc-comment), it returns `Report(..check.empty_report(), blocks_checked: 1, problems: [])`.

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
