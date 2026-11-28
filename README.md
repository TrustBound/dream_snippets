<div align="center">
  <img src="https://raw.githubusercontent.com/TrustBound/dream/main/ricky_and_lucy.png" alt="Ricky Moony and Lucy, a moon shaped mascot for Dream with the star shaped mascot for Gleam, each with cute cartoon eyes and a smile" width="200">

<b>Checks that every code block in a Gleam project's docs matches a tested snippet file.</b>

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

# dream_snippets

A code block with no tested snippet can be wrong, and nobody finds out until a reader tries it. dream_snippets is the check that every [Dream](https://github.com/TrustBound/dream) repository runs in CI to stop that: each Gleam code block in the README, the guides and the doc comments must be a copy of a snippet file that the tests compile and run. It works in any Gleam project on GitHub.

Sent here by a "not in the exact format" message? Copy the heading and badges from [Copy a badge](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md#copy-a-badge) in the Tested code blocks guide.

## Features

- ✅ Proves every fenced code block in Markdown docs and in `///` and `////` doc comments, each in the way that fits its kind, and skips none in silence
- ✅ Checks each `gleam` block in Markdown docs and in `///` and `////` doc comments
- ✅ Compares the block with the linked snippet file, or a line range of it, byte for byte
- ✅ Checks that each README example links to the guide section that shows it
- ✅ Compares each file, command and output block with the file that the tests or CI use, from the `tested_files` setting
- ✅ Proves `gleam add` lines and `toml` dependency lines with `gleam.toml`, with no file
- ✅ Counts the blocks marked as an illustration, and finds Gleam code hidden in them
- ✅ Checks `diff` blocks against the real `git diff` from a release tag
- ✅ Checks code at an older release against the file at that release tag
- ✅ Checks the release notes and changelog sections of an older release against the files at its tag, so a version bump needs no change to them
- ✅ Checks that release notes follow the release notes template
- ✅ Reads the repository and the release tag from `gleam.toml`, so it needs no setup
- ✅ No network access

## Installation

```bash
gleam add --dev dream_snippets
```

## Quick Start

Run the check from the project root:

### Run the check <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/scripts/check.sh#L10"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a> <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/docs/guides/getting-started.md#run-the-check-"><img align="right" alt="Guide: Getting started" title="Guide: Getting started" src="https://img.shields.io/badge/%F0%9F%93%96_read-guide-blue.svg?style=flat-square"></a>

```bash
gleam run -m dream_snippets
```

It prints one line for each problem and a summary line, and it stops with exit code 1 when it finds a problem. The same check is one Gleam call:

### Check a project and read what the command prints <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/doc_check_project.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a> <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/docs/guides/use-from-gleam.md#check-a-project-and-read-what-the-command-prints-"><img align="right" alt="Guide: Use it from Gleam" title="Guide: Use it from Gleam" src="https://img.shields.io/badge/%F0%9F%93%96_read-guide-blue.svg?style=flat-square"></a>

```gleam
import dream_snippets

pub fn summary_of(directory: String) -> List(String) {
  let output = dream_snippets.output(dream_snippets.check_project(directory))
  output.standard_output
}
```

## Guides

- [Getting started](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/getting-started.md): prove the code examples of a project, from the first snippet to the check in CI
- [Tested code blocks](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md): every badge to copy, line ranges, doc comments, README examples and their guide badge
- [Fix a failed check](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/fixing-check-failures.md): each message the check prints, what it means, and the fix
- [Show an API change in an upgrade guide](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/upgrade-guides.md): diff blocks and code at an older release, proven against git
- [Release notes template](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/release-notes-template.md): write release notes that follow the template, with a complete example
- [Use it from Gleam](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/use-from-gleam.md): run the check from your tests or your own tools
- [Settings and checks reference](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/reference.md): every setting with its default, and every check

## Design Principles

dream_snippets follows Dream's [design principles](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/reference/design-principles.md) and [contributing guide](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/contributing/contributing.md).

## About Dream

[Dream](https://github.com/TrustBound/dream) is a collection of Gleam packages for building production web applications. Each package implements its standards completely, shares the same naming and style as the others, and is fully tested. TrustBound builds Dream for its own production systems and shares it in the hope that it helps yours.

dream_snippets works on its own. You don't need the rest of Dream to use it.

## Contributing

See the [Contributing Guide](https://github.com/TrustBound/dream_snippets/blob/main/CONTRIBUTING.md) for guidelines.

---

## License

MIT — see [LICENSE.md](https://github.com/TrustBound/dream_snippets/blob/main/LICENSE.md)

---

<div align="center">
  <sub>Built in Gleam, on the BEAM, by the <a href="https://github.com/trustbound/dream">Dream Team</a> ❤️</sub>
</div>
