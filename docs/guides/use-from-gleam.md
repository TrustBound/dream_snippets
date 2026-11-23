# Use it from Gleam

This guide shows how to call the check from Gleam code. The checks are pure functions in `dream_snippets/check`, and `dream_snippets` checks a whole project.

## Check one document

The checks get the snippet files and git through a `CheckContext`. Thus you can check a document with any files and history.

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
    )
  let context =
    CheckContext(
      project:,
      checked_from_version: Version(1, 0, 0),
      read_source: simplifile.read,
      tag_exists: fn(_tag) { Error(git.GitNotFound) },
      diff_from_tag: fn(_tag, _path) { Error(git.GitNotFound) },
    )
  check.check_markdown("docs/guide.md", guide, context)
}
```

`check.check_readme` checks the root README of a project, with the guide badge rules. `check.check_release_notes_template` checks that one release notes file follows the template.

## Check a project

`dream_snippets.check_project` checks a whole project in a directory. `dream_snippets.output` turns its result into the lines that the command prints.

### Check a project and read what the command prints <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/doc_check_project.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_snippets

pub fn summary_of(directory: String) -> List(String) {
  let output = dream_snippets.output(dream_snippets.check_project(directory))
  output.standard_output
}
```

## Read the settings

`config.parse` reads the project and the settings from the text of a `gleam.toml`.

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

The [API docs](https://hexdocs.pm/dream_snippets) show the rest. The [README](https://github.com/TrustBound/dream_snippets/blob/main/README.md) lists all guides.
