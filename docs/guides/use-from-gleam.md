# Use it from Gleam

The command is one way in. Everything it does is also a Gleam function, so you can run the docs check from a test, print its problems in another format, or check a document that isn't on disk at all. This guide starts with the call the command makes, and works down to the pure checks and the rules under them.

## Table of Contents

- [What you'll build](#what-youll-build)
- [Before you start](#before-you-start)
- [Which function to call](#which-function-to-call)
- [Step 1: Check a project](#step-1-check-a-project)
- [Step 2: Fail your tests when the docs are wrong](#step-2-fail-your-tests-when-the-docs-are-wrong)
- [Step 3: Print problems your own way](#step-3-print-problems-your-own-way)
- [Step 4: Check one document with a fake project](#step-4-check-one-document-with-a-fake-project)
- [Step 5: Check one document of a real project](#step-5-check-one-document-of-a-real-project)
- [Errors that stop the check](#errors-that-stop-the-check)
- [The smaller rules](#the-smaller-rules)
- [Test your code](#test-your-code)
- [Common pitfalls](#common-pitfalls)
- [Where to go next](#where-to-go-next)

## What you'll build

In this guide you'll:

- Check a project and get back the exact lines the command prints.
- Make `gleam test` fail when the docs check finds a problem.
- Turn problems into GitHub Actions annotations, so each one shows on its line in a pull request.
- Check one document with fake files and a fake git history.
- Build the same context the command builds, for a real repository.

## Before you start

You need the package as a dev dependency:

```sh
gleam add --dev dream_snippets
```

There are four modules. `dream_snippets` checks a whole project and turns the result into output. `dream_snippets/check` holds the checks, which are pure functions. `dream_snippets/config` reads `gleam.toml`. `dream_snippets/git` runs git for the blocks that need history. The examples run against the example project of the other guides, `my_app` at `0.1.0` in `me/my_app`.

## Which function to call

| Your situation | Use | Why |
|:---|:---|:---|
| Check a project on disk, as the command does | `dream_snippets.check_project` | Reads `gleam.toml`, finds the files, and runs every check with real files and real git. |
| Get the exact lines and exit status of the command | `dream_snippets.output` | Sorts the problems and formats each line and the summary. |
| Your own command with another name | `dream_snippets.main` | Checks the current directory, prints, and stops with status 1 on a problem. |
| Your own output format | `check.sort_problems`, `check.describe_reason`, `check.summary` | The pieces that `output` is made of. |
| Check text that isn't on disk, or check with fake history | `check.check_markdown` and the other `check_*` functions with a `CheckContext` | Pure functions: you give them the files and git. |

## Step 1: Check a project

`dream_snippets.check_project` does what the command does for the project in a directory. `dream_snippets.output` turns its result into the lines the command prints:

### Check a project and read what the command prints <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/doc_check_project.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_snippets

pub fn summary_of(directory: String) -> List(String) {
  let output = dream_snippets.output(dream_snippets.check_project(directory))
  output.standard_output
}
```

For the example project with one guide, `docs/guides/usage.md`, whose `gleam` block on line 5 has no badge, `summary_of` returns these two lines:

### The lines that summary_of returns <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_use_from_gleam_summary.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
docs/guides/usage.md:5: this gleam code block has no heading with the tested snippet badge directly above it (one blank line between is allowed)
1 block and 0 diff blocks checked in 1 file, 1 problem; 0 file blocks, 0 command blocks and 0 output blocks checked; 0 illustration blocks
```

`check_project` returns a `ProjectReport` with the project, the merged `Report` of every file, and the number of files checked. The paths in the problems are relative to the directory you give it. `output` gives an `Output` with `standard_output`, `standard_error` and `exit_status`: 0 with no problems, and 1 otherwise.

If you want a command of your own, for example in a `dev/` module with another name, call `dream_snippets.main()` from its `main`. It checks the current directory, prints the output, and stops the program with status 1 when there's a problem or an error.

## Step 2: Fail your tests when the docs are wrong

CI runs the check as its own step, but you'll find a stale block sooner if `gleam test` fails too. This gleeunit test passes when the command would print only its summary line:

### Fail the tests when the docs check fails <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/guide_use_from_gleam_docs_test.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_snippets

pub fn docs_test() {
  let output = dream_snippets.output(dream_snippets.check_project("."))
  let assert [_summary] = output.standard_output
}
```

`gleam test` runs in the project root, so `"."` is your project. With no problem, `standard_output` is one line, the summary. With a problem, it has more lines, and the failed `let assert` shows them. With an error that stops the check, `standard_output` is empty and the test fails too. The tests of this package run this exact function on its own docs.

## Step 3: Print problems your own way

`output` is made of smaller pieces that you can use yourself: `check.sort_problems` sorts by file and line, `check.describe_reason` gives the reason text, `check.describe_problem` gives the whole `file:line: reason` line, and `check.summary` gives the last line. `check.repository_url` gives the GitHub address of the project, if your format links to it.

Here's a function that turns each problem into a GitHub Actions annotation. Print its lines in a CI step, and GitHub shows each problem on its line of the pull request:

### Turn problems into GitHub Actions annotations <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/guide_use_from_gleam_annotations.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_snippets.{type CheckError}
import dream_snippets/check.{type Problem, type Project}
import gleam/int
import gleam/list
import gleam/result

/// One `::error` line for each problem of the project in `directory`,
/// sorted by file and line. GitHub shows each one on the line it names.
pub fn annotations(directory: String) -> Result(List(String), CheckError) {
  use checked <- result.map(dream_snippets.check_project(directory))
  checked.report.problems
  |> check.sort_problems
  |> list.map(fn(problem) { annotation(problem, checked.project) })
}

fn annotation(problem: Problem, project: Project) -> String {
  "::error file="
  <> problem.file
  <> ",line="
  <> int.to_string(problem.line)
  <> "::"
  <> check.describe_reason(problem.reason, project)
}
```

For the project of Step 1, it returns:

### The annotations of the project <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_use_from_gleam_annotations.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
Ok(["::error file=docs/guides/usage.md,line=5::this gleam code block has no heading with the tested snippet badge directly above it (one blank line between is allowed)"])
```

`describe_reason` needs the `Project`, because some messages name the repository, the version or the guide pages from `gleam.toml`.

## Step 4: Check one document with a fake project

The checks in `dream_snippets/check` never touch the disk or git. They get everything through a `CheckContext`: the project, the first checked version, a function that reads a snippet file, and three functions for git. That makes them easy to call on text you build in memory, with any files and any history:

### Check one document <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/guide_check_markdown.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_snippets/check.{
  type Report, CheckContext, GitHubRepository, Project, Version,
}
import dream_snippets/git
import simplifile

pub fn check_guide(guide: String) -> Report {
  let project =
    Project(
      name: "my_app",
      version: "1.2.0",
      repository: GitHubRepository(owner: "me", name: "my_app"),
      badge_guide: "CONTRIBUTING.md",
      release_notes_guide: "CONTRIBUTING.md",
      guides: ["docs/guides"],
      tested_files: ["test", ".github"],
      dependencies: [],
    )
  let context =
    CheckContext(
      project:,
      checked_from_version: Version(1, 0, 0, []),
      read_source: simplifile.read,
      tag_exists: fn(_tag) { Error(git.GitNotFound) },
      diff_from_tag: fn(_tag, _path) { Error(git.GitNotFound) },
      diff_between_tags: fn(_old_tag, _new_tag, _path) {
        Error(git.GitNotFound)
      },
      file_at_tag: fn(_tag, _path) { Error(git.GitNotFound) },
    )
  check.check_markdown("docs/guide.md", guide, context)
}
```

For a guide whose only block, on line 3, has no heading, it returns `Report(..check.empty_report(), blocks_checked: 1, problems: [Problem("docs/guide.md", 3, MissingBadgeHeading)])`.

The git functions here always fail with `GitNotFound`, which is fine for documents of the current version with no diff blocks and no old code. For a test of those, give lookups in a list: `tag_exists: fn(tag) { Ok(tag == "1.1.0") }`, and `file_at_tag` returning `Ok(Some(text))` for a file and `Ok(None)` for none.

There's one `check_*` function for each kind of document, all with the same arguments, a path, the text and the context:

- `check.check_markdown` for a guide or any other Markdown document. Under a `guides` directory, it allows code at an older release.
- `check.check_readme` for the root README: the same checks, plus the guide badge of each example.
- `check.check_release_notes` for one release notes file: its code blocks and the template. The blocks belong to the release in the file name, so the notes of an older release are compared with the files at its tag. `check.check_release_notes_template` checks the template only, and needs no context.
- `check.check_changelog` for a changelog. It skips the sections of versions before `checked_from_version`, and compares the section of an older release with the files at its tag.
- `check.check_gleam_source` for the doc comments of a `.gleam` file.

Each returns a `Report` with the number of Gleam blocks and diff blocks it checked and the problems, in the order of the document.

## Step 5: Check one document of a real project

To check one document of a real project with real files and real git, build the context the way `check_project` does. `config.parse` reads the project and the settings from the text of `gleam.toml`:

### Read the settings from the text of a gleam.toml <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/doc_parse_config.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_snippets/config.{type Config, type ConfigError}

pub fn read_config() -> Result(Config, ConfigError) {
  config.parse(
    "name = \"my_app\"
version = \"1.2.0\"
repository = { type = \"github\", user = \"me\", repo = \"my_app\" }

[tools.dream_snippets]
checked_from_version = \"1.0.0\"
",
  )
}
```

Then give the context the real files and the real git. `git.tag_exists`, `git.diff_from_tag`, `git.diff_between_tags` and `git.file_at_tag` run git in the directory of a `Git` value, with no shell and with options that fix the output format, so your own git settings can't change what the check sees:

### Build the context of a real project <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/guide_use_from_gleam_context.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_snippets/check.{type CheckContext, CheckContext}
import dream_snippets/config.{type Config}
import dream_snippets/git.{Git}
import simplifile

pub fn context_for(directory: String, configuration: Config) -> CheckContext {
  let repository = Git(program: "git", directory:)
  CheckContext(
    project: configuration.project,
    checked_from_version: configuration.checked_from_version,
    read_source: fn(path) { simplifile.read(directory <> "/" <> path) },
    tag_exists: fn(tag) { git.tag_exists(repository, tag) },
    diff_from_tag: fn(tag, path) { git.diff_from_tag(repository, tag, path) },
    diff_between_tags: fn(old_tag, new_tag, path) {
      git.diff_between_tags(repository, old_tag, new_tag, path)
    },
    file_at_tag: fn(tag, path) { git.file_at_tag(repository, tag, path) },
  )
}
```

In a project with the tag `0.1.0`, `context.tag_exists("0.1.0")` returns `Ok(True)`. With the snippet of [Getting started](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/getting-started.md) in the project, `check.check_markdown` on a guide that shows it returns `Report(..check.empty_report(), blocks_checked: 1, problems: [])`.

`git.run` is the function under the three: it runs git with a list of arguments and returns its standard output. The check never gives it a tag or a path that fails `check.is_safe_tag` or `check.is_safe_path`, and you shouldn't either.

## Errors that stop the check

Some problems aren't about a code block: `gleam.toml` can't be used, or a file can't be read. Then `check_project` returns `Error(CheckError)`, and `output` puts one line on standard error, `error: <description>`, with exit status 1. `dream_snippets.describe_error` gives the description, `config.describe_error` describes a `ConfigError`, and `git.describe_error` describes a `GitError`.

A root that `[tools.dream_snippets]` sets but that doesn't exist, `MissingRoot("docs")`:

### The error of a missing root <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_use_from_gleam_missing_root.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
error: docs is set in [tools.dream_snippets] in gleam.toml, but it does not exist
```

A setting the check doesn't know, here `guide` instead of `guides`:

### The error of an unknown setting <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_use_from_gleam_unknown_setting.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
error: tools.dream_snippets.guide in gleam.toml is not a setting; the settings are markdown, changelog, release_notes, gleam_source, checked_from_version, guides, badge_guide, release_notes_guide, tested_files
```

For a directory with no `gleam.toml`, `annotations` from [Step 3](#step-3-print-problems-your-own-way) returns an `Error`, and `describe_error` gives:

### The description of a missing gleam.toml <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/outputs/guide_use_from_gleam_no_toml.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
Cannot read gleam.toml: No such file or directory
```

[Fix a failed check](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/fixing-check-failures.md#errors-that-stop-the-check) lists every error with its fix.

## The smaller rules

The checks are built from smaller pure functions, and they're public too. Use them when a tool of your own must read the same links, headings and versions as the check. Each has a tested example in its doc comment on HexDocs.

| You want to | Use |
|:---|:---|
| Read the tested snippet badge and the guide badge of a heading | `check.parse_example_heading` |
| Read only the tested snippet badge, or the diff badge | `check.parse_badge_heading`, `check.parse_diff_badge_heading` |
| Read the code at an older release badge and its link | `check.parse_old_code_heading` |
| Read a snippet badge address, or its `#L` anchor | `check.parse_snippet_link`, `check.parse_line_selection` |
| Read a guide badge address, or a diff badge address | `check.parse_guide_link`, `check.parse_compare_link` |
| Get the anchor of one heading, or of every heading of a document | `check.heading_slug`, `check.heading_anchors` |
| Tell whether a path is a guide | `check.is_guide_path` |
| Read the kind of a fence from its info string | `check.classify_fence` |
| Tell whether a file, command or output block can link to a path | `check.is_tested_file` |
| Get the requirement that the dependency lines of a release show | `check.release_requirement` |
| Start a report, or add two reports | `check.empty_report`, `check.add_report` |
| Read and compare versions, in semver order | `check.parse_release_version`, `check.compare_versions` |
| Keep a message on one line | `check.one_line` |
| Read the version of a release notes file, and whether the check reads it | `check.release_notes_version`, `check.is_checked_release_notes` |
| Read the name of a changelog section, and whether the check reads it | `check.changelog_section_name`, `check.is_checked_changelog_section` |
| Tell whether a tag or a path is safe to give to git | `check.is_safe_tag`, `check.is_safe_path` |
| Get the anchor that names a file in a compare view | `check.path_digest` |
| Split a git diff into hunks | `check.parse_hunks` |
| Tell whether a line looks like Gleam code | `check.looks_like_gleam` |
| Get the places the check reads with no settings | `config.default_roots` |
| Get the release notes template | `check.release_notes_template` |

## Test your code

Two kinds of tests cover code that uses this package:

- For a tool that checks text, call the `check_*` functions with a `CheckContext` of fakes, as in [Step 4](#step-4-check-one-document-with-a-fake-project), and assert the whole `Report`. The fakes make the test independent of your disk and your git history.
- For a tool that checks a project, write a small project to a temporary directory and call `check_project` on it, as the tests of this guide do. Use `git init` and `git tag` in that directory when you need history.

The tests of this guide assert each value shown here, for example that `annotations` returns the one line of Step 3 for the example project, and that `describe_error` gives `Cannot read gleam.toml: No such file or directory` for a directory with no `gleam.toml`.

## Common pitfalls

**Paths relative to the wrong directory.** *Symptom:* every badge fails with `which is not a file in this repository`. *Fix:* `read_source` gets paths relative to the project root. Join them with the root, as `context_for` does, or run from the root.

**Calling `main` in a test.** *Symptom:* the test run stops in the middle. *Fix:* `main` halts the program with status 1 when there's a problem. In a test, call `check_project` and `output` instead.

**Describing a reason with the wrong project.** *Symptom:* messages point at the wrong guide page or the wrong repository. *Fix:* pass the `project` of the `ProjectReport`, or the one from `config.parse`, to `describe_reason` and `describe_problem`.

**Expecting the problems sorted.** *Symptom:* a `Report` lists problems in document order, file by file. *Fix:* call `check.sort_problems` before you print them, as `output` does.

## Where to go next

- [Getting started](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/getting-started.md): the command, from the first run to CI.
- [Fix a failed check](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/fixing-check-failures.md): every message and every error.
- [Settings and checks reference](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/reference.md): what `config.parse` reads, and the defaults.
- [API reference on HexDocs](https://hexdocs.pm/dream_snippets/): every type and function, each with a tested example.
