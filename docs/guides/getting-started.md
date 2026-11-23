# Getting started

A code example in a README or a guide is the first code most people run from your package, and it's the code nobody tests. You rename a function, the tests pass, and the docs keep the old name until a reader finds out the hard way. dream_snippets closes that gap. Each Gleam code block in your docs must be an exact copy of a snippet file that your tests compile and run, each other code block must be proven too, and one command checks it all. This guide takes a project from no checked docs to a check that runs in CI.

## Table of Contents

- [What you'll build](#what-youll-build)
- [Before you start](#before-you-start)
- [Step 1: Run the check on your project](#step-1-run-the-check-on-your-project)
- [Step 2: Write a snippet and its test](#step-2-write-a-snippet-and-its-test)
- [Step 3: Show the snippet in a guide](#step-3-show-the-snippet-in-a-guide)
- [Step 4: Run the check again](#step-4-run-the-check-again)
- [Step 5: Read your first failure](#step-5-read-your-first-failure)
- [Step 6: Show the example in your README](#step-6-show-the-example-in-your-readme)
- [Step 7: Run the check in CI](#step-7-run-the-check-in-ci)
- [Test your code](#test-your-code)
- [Common pitfalls](#common-pitfalls)
- [Where to go next](#where-to-go-next)

## What you'll build

In this guide you'll:

- Run the check on a project and read its summary line.
- Write a snippet file and a test that runs it.
- Show the snippet in a guide, with the heading and badge that tie the block to the file.
- Break the snippet on purpose, and read the message the check prints.
- Show the same example in your README, with a link to the guide.
- Add the check to CI, so a pull request with a stale example fails.

## Before you start

You need a Gleam project with a `repository` on GitHub in its `gleam.toml`. The check reads three fields there and needs nothing else. Here's the `gleam.toml` of the example project, which the tests of this guide use:

### The gleam.toml of the example project <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/fixtures/my_app/gleam.toml"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```toml
name = "my_app"
version = "0.1.0"
repository = { type = "github", user = "me", repo = "my_app" }
```

Every badge link points at that repository, at the tag of that `version`. The examples in this guide use `me/my_app` at `0.1.0`. Use your own names.

Add the package as a dev dependency:

```sh
gleam add --dev dream_snippets
```

Run every command in this guide from the project root.

## Step 1: Run the check on your project

Run the check before you change anything. This is the line that the check script of this package runs in CI:

### Run the check <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/scripts/check.sh#L10"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```sh
gleam run -m dream_snippets
```

In a new project with a README that has no code and one module in `src/`, it prints one line:

### The summary of a project with no code blocks <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_getting_started_step_1.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
0 blocks and 0 diff blocks checked in 2 files, 0 problems; 0 file blocks, 0 command blocks and 0 output blocks checked; 0 illustration blocks
```

The part before the `;` counts the `gleam` blocks, the `diff` blocks, the files and the problems. The part after it counts the blocks of the other kinds, which [Tested code blocks](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md#which-proof-to-use) explains. The check found two files to read: `README.md` and `src/my_app.gleam`. With no settings, it reads `README.md`, `SECURITY.md`, `docs/`, `examples/`, `CHANGELOG.md`, `releases/` and the doc comments in `src/`, and it skips each one that your project doesn't have. It never walks `build/`, `deps/`, `_build/` or `node_modules/`. It doesn't use the network either: it reads your files and, for some blocks, your local git history.

If your docs already have code blocks, you'll see one line for each problem before the summary. That's fine. The steps below show how to make one block pass, and [Fix a failed check](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/fixing-check-failures.md) explains every message.

## Step 2: Write a snippet and its test

A snippet is a small Gleam file under `test/snippets/` that holds exactly the code your docs show. It lives under `test/`, so it compiles with your tests and can use your dev dependencies, but it never ships in your package.

Name each snippet after the guide that shows it and what it shows, as `guide_<guide>_<what>.gleam`. Then you can tell from a file name which doc breaks when the file changes. Here's the snippet for a getting started guide, `test/snippets/guide_getting_started_greeting.gleam`:

### The snippet file <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/guide_getting_started_greeting.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import gleam/string

pub fn greeting(name: String) -> String {
  "Hello, " <> string.capitalise(name) <> "!"
}
```

In your project, the snippet calls your own package, for example `import my_app/greeting`. The file on disk starts with a `////` comment that says which guide shows it. The block above leaves that comment out, and the check allows that. More on this in [Step 3](#step-3-show-the-snippet-in-a-guide).

A snippet that only compiles proves less than you'd like. Run it from a test and assert what it returns, so the test fails when the code stops doing what the docs say. With gleeunit, the default test framework of `gleam new`, the test is a public function whose name ends in `_test`:

### The test of the snippet <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/guide_getting_started_greeting_test.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import snippets/guide_getting_started_greeting

pub fn greeting_test() {
  let assert "Hello, Lucy!" = guide_getting_started_greeting.greeting("lucy")
}
```

Put it with your other tests, for example in `test/snippets_test.gleam`. `gleam test` now compiles the snippet and fails when `greeting("lucy")` stops returning `"Hello, Lucy!"`. Any test framework works. The check doesn't look at your tests at all. It only proves that the docs show the code of the file, and the tests prove that the file works.

## Step 3: Show the snippet in a guide

Now put the code in a guide, `docs/guides/getting-started.md`. The block needs a heading directly above it, and the heading ends with the "tested snippet" badge. The badge is a link to the snippet file on GitHub, at the tag of your version, with a fixed image:

```markdown
### Greet a user <a href="https://github.com/me/my_app/blob/0.1.0/test/snippets/guide_getting_started_greeting.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
```

Directly under the heading, with at most one blank line between, put a `gleam` fence with the code of the file. The guide of the example project is:

1. `# Getting started` on line 1, and a blank line.
2. The heading above on line 3, and a blank line.
3. A ```` ```gleam ```` fence on line 5, the five lines of the snippet code, and the closing fence.

Here's what each part of the badge does:

- `https://github.com/me/my_app` must be the `repository` in `gleam.toml`. A link to any other repository or host fails.
- `blob/0.1.0` must be the `version` in `gleam.toml`. HexDocs and Hex show your docs without your repository, so the link is a full address at a fixed tag, and it shows the same file the docs were checked against.
- `test/snippets/guide_getting_started_greeting.gleam` is the path from the project root. The check reads that file from your working tree, not from GitHub.
- The `<img ...>` part must be exactly this text. Copy it, don't type it.

The block must be the same as the file, byte for byte. A whole-file block may leave out the `////` comment at the top of the file and the blank line after it, as this one does. To show only some lines, end the link with a line range such as `#L5-L9`. [Tested code blocks](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md) shows that and the other forms.

## Step 4: Run the check again

Run `gleam run -m dream_snippets` again:

### The summary with one tested block <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_getting_started_step_4.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
1 block and 0 diff blocks checked in 3 files, 0 problems; 0 file blocks, 0 command blocks and 0 output blocks checked; 0 illustration blocks
```

The check found the new guide, compared its one block with the snippet file, and found no problem. It stops with exit status 0, so a script or a CI step that runs it goes on.

## Step 5: Read your first failure

Now change the snippet the way a real change would: edit `"Hello, "` in `test/snippets/guide_getting_started_greeting.gleam` to `"Hi, "`, update the test, and leave the guide alone. The tests pass, because the test follows the code. The check doesn't:

### The message of a changed snippet <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_getting_started_step_5_changed.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
docs/guides/getting-started.md:5: the code block is not the same as test/snippets/guide_getting_started_greeting.gleam; the first difference is at line 9
1 block and 0 diff blocks checked in 3 files, 1 problem; 0 file blocks, 0 command blocks and 0 output blocks checked; 0 illustration blocks
```

Each problem is one line in the form `file:line: reason`, sorted by file and line, and the summary comes last. The check stops with exit status 1, so the CI step fails. Read it from left to right:

- `docs/guides/getting-started.md:5` is the opening fence of the block that is out of date.
- `test/snippets/guide_getting_started_greeting.gleam` is the file the badge links to.
- `line 9` is the line of the guide where the block and the file first differ. Line 9 is the line with `"Hello, "`.

The fix is always the same: copy the code from the snippet file into the block again. The code is the truth, because the tests run it. Don't edit the block to fix the message.

A block with no badge fails too. If the heading above the block is only `### Greet a user`, the check prints:

### The message of a block with no badge <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_getting_started_step_5_heading.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
docs/guides/getting-started.md:5: this gleam code block has no heading with the tested snippet badge directly above it (one blank line between is allowed)
1 block and 0 diff blocks checked in 3 files, 1 problem; 0 file blocks, 0 command blocks and 0 output blocks checked; 0 illustration blocks
```

## Step 6: Show the example in your README

Most readers meet your package in the README, so put the example there too. A README example has one more rule: its heading has a second badge, the guide badge, which links to the guide section that explains the example. If you copy the heading from the guide as it is, the check prints:

### The message of a README example with no guide badge <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_getting_started_step_6_no_guide_badge.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
README.md:5: this README example heading has no guide badge after its tested snippet badge; copy the heading from https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html
2 blocks and 0 diff blocks checked in 3 files, 1 problem; 0 file blocks, 0 command blocks and 0 output blocks checked; 0 illustration blocks
```

The guide badge comes after the tested snippet badge, with one space between them:

```markdown
### Greet a user <a href="https://github.com/me/my_app/blob/0.1.0/test/snippets/guide_getting_started_greeting.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a> <a href="https://github.com/me/my_app/blob/0.1.0/docs/guides/getting-started.md#greet-a-user-"><img align="right" alt="Guide" src="https://img.shields.io/badge/%F0%9F%93%96_read-guide-blue.svg?style=flat-square"></a>
```

The link names the guide file at the same tag, and `#greet-a-user-` is the anchor GitHub gives the guide heading `### Greet a user` with its badge. The badge leaves a space at the end of the heading text, and that space becomes the last hyphen. The check makes sure that the guide exists, that it has a heading with that anchor, and that it shows the same snippet file. With the guide badge in place:

### The summary with the README example <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_getting_started_step_6.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
2 blocks and 0 diff blocks checked in 3 files, 0 problems; 0 file blocks, 0 command blocks and 0 output blocks checked; 0 illustration blocks
```

[Tested code blocks](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md#step-4-add-an-example-to-the-readme) has the full rules for README examples and for anchors.

## Step 7: Run the check in CI

The check is only worth something when it runs on every change. Add two things to your workflow: a checkout with the tags, and a step after the tests that runs the check. This block is a template for your own workflow, so no file of this package holds it, and it's marked as an illustration:

```yaml illustration
- uses: actions/checkout@v4
  with:
    fetch-depth: 0
- name: Check docs snippets
  run: gleam run -m dream_snippets
```

The examples in this guide don't need git. A `diff` block, a block of code at an older release, and the release notes of an older release do, because the check reads your release tags. `actions/checkout` makes a shallow clone with no tags, so `fetch-depth: 0` asks for the full history.

If you use `make`, a target keeps the command short for local runs. This is the target of this package's own Makefile:

### The check-snippets target <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/Makefile#L22-L23"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```makefile
check-snippets:
	@gleam run -m dream_snippets
```

When your docs show a command, such as this `gleam run` line, keep the command in a script that CI runs, and link the block to its line. [Tested code blocks](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md#step-6-show-a-command) shows how.

## Test your code

The snippet tests are the tests of your docs. Two habits keep them honest:

- Assert the exact value the docs show or describe. A test that only calls the snippet proves that it doesn't crash, not that the docs are right.
- Keep every snippet file compiling. `gleam test` compiles everything under `test/`, so a snippet that no longer compiles stops the whole test run, even when no test calls it. That's what you want: a change that breaks an example breaks the build.

If you want the docs check to be part of `gleam test` itself, call it from a test. [Use it from Gleam](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/use-from-gleam.md) shows how.

## Common pitfalls

**Editing the block instead of the file.** *Symptom:* you fix a block until the check passes, and the next release breaks it again. *Fix:* edit the snippet file and its test, then copy the file into the block. The block is a copy, never the original.

**A badge that links to a tag that doesn't exist yet.** *Symptom:* the badge link gives a 404 on GitHub before the release. *Fix:* nothing to fix. The link names the tag of the version in `gleam.toml`, so it works from the moment you push that tag. The check reads the local file, so it doesn't care.

**Forgetting to bump the badges.** *Symptom:* after you change `version` in `gleam.toml`, every badge fails with `the badge link uses the tag 0.1.0, but this file must link at the tag 0.2.0`. *Fix:* replace the old tag in the badge links of your docs, for example with your editor's search and replace on `blob/0.1.0/`.

**A block that nothing proves.** *Symptom:* `this text code block has no heading with the tested snippet badge directly above it`. *Fix:* every code block needs a proof. Output goes in an output file that a test compares, a command in a script that CI runs, and a config file in the file itself. [Tested code blocks](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md#which-proof-to-use) shows each form.

**Two blank lines between the heading and the block.** *Symptom:* `this gleam code block has no heading with the tested snippet badge directly above it`, although the heading is there. *Fix:* at most one blank line may sit between the heading and the fence.

## Where to go next

- [Tested code blocks](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md): every badge form to copy, line ranges, doc comments, README examples and anchors.
- [Fix a failed check](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/fixing-check-failures.md): each message the check prints, what it means and how to fix it.
- [Show an API change in an upgrade guide](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/upgrade-guides.md): diff blocks and code at an older release.
- [Release notes template](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/release-notes-template.md): write release notes that pass the check.
- [Settings and checks reference](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/reference.md): every setting with its default, and every check.
- [API reference on HexDocs](https://hexdocs.pm/dream_snippets/): the modules `dream_snippets`, `dream_snippets/check`, `dream_snippets/config` and `dream_snippets/git`.
