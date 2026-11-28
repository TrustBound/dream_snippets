<div align="center">
  <img src="https://raw.githubusercontent.com/TrustBound/dream/main/ricky_and_lucy.png" alt="Ricky Moony and Lucy, a moon shaped mascot for Dream with the star shaped mascot for Gleam, each with cute cartoon eyes and a smile" width="200">

<b>Every code block in your docs, proven by a test</b>

</div>

<br />

<div align="center">
  <a href="https://hex.pm/packages/dream_snippets"><img src="https://img.shields.io/hexpm/v/dream_snippets" alt="Hex Package"></a>
  <a href="https://github.com/TrustBound/dream_snippets/releases"><img src="https://img.shields.io/github/v/release/TrustBound/dream_snippets?label=Release" alt="Latest Release"></a>
  <a href="https://hexdocs.pm/dream_snippets"><img src="https://img.shields.io/badge/hex-docs-lightgreen.svg" alt="HexDocs"></a>
  <a href="https://github.com/TrustBound/dream_snippets/actions/workflows/ci.yml?query=branch%3Amain"><img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/TrustBound/dream_snippets/badges/coverage.json" alt="Coverage"></a>
  <a href="https://github.com/TrustBound/dream_snippets/blob/main/LICENSE.md"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"></a>
  <a href="https://gleam.run"><img src="https://img.shields.io/badge/gleam-%E2%9C%A8-ffaff3" alt="Gleam"></a>
</div>

<br />

## What is Dream Snippets?

Dream Snippets is the check that stops a code example in your docs from being wrong without anyone noticing. Each Gleam code block in a README, a guide or a doc comment must be a byte-for-byte copy of a snippet file that your tests compile and run, and the check fails the build when one differs. It reads the repository and the release tag from `gleam.toml`, so it needs no setup, and it works in any Gleam project on GitHub.

## Features

### Every block is proven

Each kind of block is proven in the way that fits it, and none is skipped in silence. [Read more](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md#which-proof-to-use).

| Feature                           | What you get                                                                                                                      |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| 🧪 **Gleam blocks**               | Compared byte for byte with the linked snippet file, or a line range of it, in Markdown docs and in `///` and `////` doc comments |
| 📄 **Files, commands and output** | Compared with the file that the tests or CI use, from the `tested_files` setting                                                  |
| 📦 **Packages**                   | `gleam add` lines and `toml` dependency lines are proven with `gleam.toml`, with no file                                          |
| 🕵️ **Illustrations**              | Blocks marked as an illustration are counted, and Gleam code hidden in them is found                                              |

### README examples

Each README example links to the guide section that shows it. [Read more](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md#step-4-add-an-example-to-the-readme).

| Feature                            | What you get                                                                           |
| ---------------------------------- | -------------------------------------------------------------------------------------- |
| 🏷️ **Standard heading and badges** | The check finds a README example by its heading and its two badges                     |
| 🔗 **Guide link**                  | The check fails when a README example does not link to the guide section that shows it |

### Upgrades and releases

Old code and release notes are checked against git. [Read more](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/upgrade-guides.md).

| Feature                       | What you get                                                                                                                                     |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| 🔀 **Diff blocks**            | Checked against the real `git diff` from a release tag                                                                                           |
| 🕰️ **Older releases**         | Code, release notes and changelog sections of an older release are compared with the files at its tag, so a version bump needs no change to them |
| 📝 **Release notes template** | Checks that release notes follow the template                                                                                                    |

### Easy to run

One command in CI, or one Gleam call in your tests. [Read more](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/use-from-gleam.md).

| Feature           | What you get                                                                              |
| ----------------- | ----------------------------------------------------------------------------------------- |
| ⌨️ **One command** | `gleam run -m dream_snippets` prints one line for each problem and stops with exit code 1 |
| 🧰 **From Gleam** | `check_project` returns the result, for your tests or your own tools                      |
| 🔌 **No network** | The check reads files and git only                                                        |

## A Quick Example

Run the check from the project root:

### Run the check <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/scripts/check.sh#L10"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a> <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/docs/guides/getting-started.md#run-the-check-"><img align="right" alt="Guide: Getting started" title="Guide: Getting started" src="https://img.shields.io/badge/%F0%9F%93%96_read-guide-blue.svg?style=flat-square"></a>

```bash
gleam run -m dream_snippets
```

**Run this:** `gleam run -m dream_snippets` → one line for each problem and a summary line such as `32 blocks and 0 diff blocks checked in 9 files, 0 problems`, and exit code 1 when there is a problem.

## Installation

```sh
gleam add --dev dream_snippets
```

## Guides

Sent here by a "not in the exact format" message? Copy the heading and badges from [Copy a badge](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md#copy-a-badge) in the Tested code blocks guide.

- [Getting started](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/getting-started.md): prove the code examples of a project, from the first snippet to the check in CI
- [Tested code blocks](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md): every badge to copy, line ranges, doc comments, README examples and their guide badge
- [Fix a failed check](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/fixing-check-failures.md): each message the check prints, what it means, and the fix
- [Show an API change in an upgrade guide](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/upgrade-guides.md): diff blocks and code at an older release, proven against git
- [Release notes template](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/release-notes-template.md): write release notes that follow the template, with a complete example
- [Use it from Gleam](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/use-from-gleam.md): run the check from your tests or your own tools
- [Settings and checks reference](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/reference.md): every setting with its default, and every check
- [API reference](https://hexdocs.pm/dream_snippets): every module and function on HexDocs

## Requirements

- Gleam 1.19.2 or newer on Erlang/OTP 28 (the versions CI uses).
- `git` on the `PATH` for the checks of diff blocks and older releases.
- A GitHub repository, so the check can read the repository and the release tag from `gleam.toml`.

## About Dream

[Dream](https://github.com/TrustBound/dream) is a collection of Gleam packages for building production web applications. Each package implements its standards completely, shares the same naming and style as the others, and is fully tested. TrustBound builds Dream for its own production systems and shares it in the hope that it helps yours.

Dream Snippets works on its own. You don't need the rest of Dream to use it.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE.md](https://github.com/TrustBound/dream_snippets/blob/main/LICENSE.md)
