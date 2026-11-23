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

Sent here by a "not in the exact format" message? Copy the heading and badges from the [Tested code blocks](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md) guide.

## Features

- ✅ Checks each `gleam` block in Markdown docs and in `///` and `////` doc comments
- ✅ Compares the block with the linked snippet file, or a line range of it, byte for byte
- ✅ Checks that each README example links to the guide section that shows it
- ✅ Finds Gleam code hidden in `text`, `bash` or unlabelled fences
- ✅ Checks `diff` blocks against the real `git diff` from a release tag
- ✅ Checks that release notes follow the release notes template
- ✅ Reads the repository and the release tag from `gleam.toml`, so it needs no setup
- ✅ No network access

## Installation

```bash
gleam add --dev dream_snippets
```

## Quick Start

Run the check from the project root:

```bash
gleam run -m dream_snippets
```

It prints one line for each problem and a summary line, and it stops with exit code 1 when it finds a problem. The same check is one Gleam call:

### Check a project and read what the command prints <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/doc_check_project.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a> <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/docs/guides/use-from-gleam.md#check-a-project-and-read-what-the-command-prints"><img align="right" alt="Guide" src="https://img.shields.io/badge/%F0%9F%93%96_read-guide-blue.svg?style=flat-square"></a>

```gleam
import dream_snippets

pub fn summary_of(directory: String) -> List(String) {
  let output = dream_snippets.output(dream_snippets.check_project(directory))
  output.standard_output
}
```

## Guides

- [Getting started](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/getting-started.md): install the package, run the check, and run it in CI
- [Tested code blocks](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/tested-code-blocks.md): the exact heading and badge forms, the guide badge of README examples, and diff blocks
- [Release notes template](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/release-notes-template.md): the template that release notes must follow
- [Configuration](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/configuration.md): the settings in `gleam.toml` and their defaults
- [Use it from Gleam](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/use-from-gleam.md): call the checks from Gleam code

## Design Principles

dream_snippets follows Dream's [design principles](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/reference/design-principles.md) and [contributing guide](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/contributing/contributing.md).

## About Dream

This package was first built inside the [Dream](https://github.com/TrustBound/dream) web toolkit, as the check behind its tested docs. It is standalone and can be used in any Gleam project. It follows Dream's design principles and will be maintained as part of the Dream ecosystem.

## Contributing

See the [Contributing Guide](https://github.com/TrustBound/dream_snippets/blob/main/CONTRIBUTING.md) for guidelines.

---

## License

MIT — see [LICENSE.md](https://github.com/TrustBound/dream_snippets/blob/main/LICENSE.md)

---

<div align="center">
  <sub>Built in Gleam, on the BEAM, by the <a href="https://github.com/trustbound/dream">Dream Team</a> ❤️</sub>
</div>
