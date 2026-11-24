//// Reads what the check needs from the `gleam.toml` of a project.
////
//// The badge links of a project point at its own GitHub repository, at the
//// tag of its own version, so the check reads `name`, `version` and
//// `repository` from `gleam.toml`. The places that it reads, and the first
//// version whose changelog section and release notes it checks, come from
//// an optional `[tools.dream_snippets]` table. These are the defaults:
////
//// ### The default settings <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/fixtures/settings/defaults.toml"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
////
//// ```toml
//// [tools.dream_snippets]
//// markdown = ["README.md", "SECURITY.md", "docs", "examples"]
//// changelog = ["CHANGELOG.md"]
//// release_notes = ["releases"]
//// gleam_source = ["src"]
//// checked_from_version = "0.0.0"
//// guides = ["docs/guides"]
//// tested_files = ["test", ".github"]
//// badge_guide = "https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html"
//// release_notes_guide = "https://hexdocs.pm/dream_snippets/guides/release-notes-template.html"
//// ```
////
//// Each setting is optional. The values above are the defaults. The
//// default `checked_from_version` checks every changelog section and every
//// release note. `tested_files` are the files and directories that the tests
//// or CI of the project use: a file, command or output block links to a file
//// that is one of them or under one of them. `guides` are the directories
//// that hold the guides of the
//// project: the guide badge of a README example links to a `.md` file
//// under one of them. The default `badge_guide` is the "Tested code
//// blocks" guide of this package on HexDocs, which shows the exact
//// headings and badges to copy. The default `release_notes_guide` is the
//// "Release notes template" guide of this package on HexDocs. A root list
//// that is set replaces the default list of its kind, and each of its
//// paths must exist. A default path that does not exist is skipped.
////
//// A `release_notes` path is a directory or one file. A directory is
//// walked for `release-<version>.md` files, and files with other names are
//// skipped. A file path must have a name of the form
//// `release-<version>.md`, or the check reports one problem at line 1 of
//// that file. In both cases, the notes of a version before
//// `checked_from_version` are skipped.

import dream_snippets/check.{
  type DocumentKind, type Project, type Version, Changelog, GitHubRepository,
  GleamSource, MarkdownDocument, Project, ReleaseNotes, Version,
}
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import tom.{type Toml}

/// The path of the file that the configuration is read from, relative to
/// the project root.
pub const gleam_toml_path = "gleam.toml"

/// The first version whose release notes and changelog section are checked
/// when `checked_from_version` is not set: `0.0.0`, so every version is
/// checked.
pub const default_checked_from_version = Version(0, 0, 0, [])

/// The document that a malformed badge message names when `badge_guide` is
/// not set: the "Tested code blocks" guide of this package on HexDocs,
/// which shows the exact headings and badges to copy.
pub const default_badge_guide =
  "https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html"

/// The document that a release notes template message names when
/// `release_notes_guide` is not set: the "Release notes template" guide of
/// this package on HexDocs, which shows the template.
pub const default_release_notes_guide =
  "https://hexdocs.pm/dream_snippets/guides/release-notes-template.html"

/// The directories that hold the guides of a project when `guides` is not
/// set. The guide badge of a README example links to a `.md` file under
/// one of them.
pub const default_guides = ["docs/guides"]

/// The files and directories that the tests or CI of a project use when
/// `tested_files` is not set: `test`, where the tests read their files, and
/// `.github`, where CI reads its workflows and scripts. A file, command or
/// output block links to a file that is one of them or under one of them.
pub const default_tested_files = ["test", ".github"]

/// Whether a checked root must exist.
pub type RootPresence {
  /// The root is set in `[tools.dream_snippets]`, so a missing root is an
  /// error.
  MustExist
  /// The root is a default, so a missing root is skipped.
  MayBeMissing
}

/// A file, or a directory that is walked for files of one kind, relative
/// to the project root.
pub type CheckedRoot {
  CheckedRoot(path: String, kind: DocumentKind, presence: RootPresence)
}

/// Everything the check reads from `gleam.toml`.
pub type Config {
  Config(
    project: Project,
    roots: List(CheckedRoot),
    checked_from_version: Version,
  )
}

/// Why `gleam.toml` cannot be used.
pub type ConfigError {
  /// The file is not valid TOML: the parser found `got` where it expected
  /// `expected`.
  InvalidToml(got: String, expected: String)
  /// The file sets the same key twice.
  RepeatedKey(key: String)
  /// The file has no `version = "..."` line before its first `[section]`.
  VersionNotFound
  /// The file has no `name = "..."` line before its first `[section]`.
  NameNotFound
  /// The file has no `repository` table with `type`, `user` and `repo`.
  RepositoryNotFound
  /// The repository is not on GitHub. `repository_type` is its `type`.
  UnsupportedRepository(repository_type: String)
  /// A key has a value of the wrong type. `key` is the dotted key,
  /// `expected` says what it must be, and `found` is the TOML type it has.
  WrongSettingType(key: String, expected: String, found: String)
  /// A root list or `guides` in `[tools.dream_snippets]` holds a value that
  /// is not a string. `key` is the dotted key of the list.
  RootNotAString(key: String)
  /// `[tools.dream_snippets]` has a key that the check does not know.
  UnknownSetting(key: String)
  /// `checked_from_version` is not a `major.minor.patch` version.
  InvalidCheckedFromVersion(value: String)
}

const settings_key = "tools.dream_snippets"

const root_settings = [
  #("markdown", MarkdownDocument),
  #("changelog", Changelog),
  #("release_notes", ReleaseNotes),
  #("gleam_source", GleamSource),
]

const known_settings = [
  "markdown", "changelog", "release_notes", "gleam_source",
  "checked_from_version", "guides", "badge_guide", "release_notes_guide",
  "tested_files",
]

/// The places that the check reads when `[tools.dream_snippets]` sets none:
/// `README.md`, `SECURITY.md`, `docs/` and `examples/` as Markdown,
/// `CHANGELOG.md` as the changelog, `releases/` as release notes, and the
/// doc comments in `src/`. Each one may be missing.
///
/// These are never walked, on purpose: `build/`, `deps/`, `_build/` and
/// `node_modules/`, which hold build output and the docs of other projects.
///
/// ## Examples
///
/// ### List the default roots <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/doc_default_roots.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_snippets/config
/// import gleam/list
///
/// pub fn default_paths() -> List(String) {
///   // Returns [
///   //   "README.md", "SECURITY.md", "docs", "examples", "CHANGELOG.md",
///   //   "releases", "src",
///   // ]
///   list.map(config.default_roots(), fn(root) { root.path })
/// }
/// ```
pub fn default_roots() -> List(CheckedRoot) {
  [
    CheckedRoot("README.md", MarkdownDocument, MayBeMissing),
    CheckedRoot("SECURITY.md", MarkdownDocument, MayBeMissing),
    CheckedRoot("docs", MarkdownDocument, MayBeMissing),
    CheckedRoot("examples", MarkdownDocument, MayBeMissing),
    CheckedRoot("CHANGELOG.md", Changelog, MayBeMissing),
    CheckedRoot("releases", ReleaseNotes, MayBeMissing),
    CheckedRoot("src", GleamSource, MayBeMissing),
  ]
}

/// Reads the configuration from the text of `gleam.toml`.
///
/// ## Parameters
///
/// - `gleam_toml`: the text of the file
///
/// ## Returns
///
/// The project (`name`, `version`, the GitHub `user` and `repo` of
/// `repository`, `badge_guide`, `release_notes_guide` and `guides`), the
/// checked roots and the `checked_from_version`.
///
/// ## Examples
///
/// ### Read the configuration of a project <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/doc_parse_config.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_snippets/config.{type Config, type ConfigError}
///
/// pub fn read_config() -> Result(Config, ConfigError) {
///   config.parse(
///     "name = \"my_app\"
/// version = \"1.2.0\"
/// repository = { type = \"github\", user = \"me\", repo = \"my_app\" }
///
/// [tools.dream_snippets]
/// checked_from_version = \"1.0.0\"
/// ",
///   )
/// }
/// ```
///
/// ## Errors
///
/// A `ConfigError` when the text is not valid TOML, when `name`, `version`
/// or a GitHub `repository` is missing, or when a setting in
/// `[tools.dream_snippets]` is unknown or has the wrong type.
pub fn parse(gleam_toml: String) -> Result(Config, ConfigError) {
  use document <- result.try(
    tom.parse(gleam_toml) |> result.map_error(describe_parse_error),
  )
  use name <- result.try(required_string(document, ["name"], NameNotFound))
  use version <- result.try(required_string(
    document,
    ["version"],
    VersionNotFound,
  ))
  use repository <- result.try(read_repository(document))
  use settings <- result.try(read_settings(document))
  use badge_guide <- result.try(read_badge_guide(settings))
  use release_notes_guide <- result.try(read_release_notes_guide(settings))
  use guides <- result.try(read_path_list(settings, "guides", default_guides))
  use tested_files <- result.try(read_path_list(
    settings,
    "tested_files",
    default_tested_files,
  ))
  use dependencies <- result.try(read_dependency_names(document))
  use checked_from_version <- result.try(read_checked_from_version(settings))
  use roots <- result.try(read_roots(settings))
  Ok(Config(
    project: Project(
      name:,
      version:,
      repository:,
      badge_guide:,
      release_notes_guide:,
      guides:,
      tested_files:,
      dependencies:,
    ),
    roots:,
    checked_from_version:,
  ))
}

/// Describes why `gleam.toml` cannot be used, in one line (see
/// `check.one_line`).
///
/// ## Examples
///
/// ### Describe a configuration error <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/doc_describe_config_error.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_snippets/config.{NameNotFound}
///
/// pub fn name_not_found_message() -> String {
///   // Returns "gleam.toml has no name = \"...\" line before its first [section]"
///   config.describe_error(NameNotFound)
/// }
/// ```
pub fn describe_error(error: ConfigError) -> String {
  check.one_line(error_text(error))
}

fn error_text(error: ConfigError) -> String {
  case error {
    InvalidToml(got:, expected:) ->
      gleam_toml_path
      <> " is not valid TOML: found "
      <> got
      <> " where "
      <> expected
      <> " was expected"
    RepeatedKey(key:) -> gleam_toml_path <> " sets the key " <> key <> " twice"
    VersionNotFound ->
      gleam_toml_path
      <> " has no version = \"...\" line before its first [section]"
    NameNotFound ->
      gleam_toml_path
      <> " has no name = \"...\" line before its first [section]"
    RepositoryNotFound ->
      gleam_toml_path
      <> " has no repository = { type = \"github\", user = \"...\", repo = \"...\" }"
    UnsupportedRepository(repository_type:) ->
      gleam_toml_path
      <> " names a "
      <> repository_type
      <> " repository; the badges link at GitHub, so the repository type must be github"
    WrongSettingType(key:, expected:, found:) ->
      key
      <> " in "
      <> gleam_toml_path
      <> " must be "
      <> expected
      <> ", but its TOML type is "
      <> found
    RootNotAString(key:) ->
      key <> " in " <> gleam_toml_path <> " must be an array of strings"
    UnknownSetting(key:) ->
      settings_key
      <> "."
      <> key
      <> " in "
      <> gleam_toml_path
      <> " is not a setting; the settings are "
      <> string.join(known_settings, ", ")
    InvalidCheckedFromVersion(value:) ->
      settings_key
      <> ".checked_from_version in "
      <> gleam_toml_path
      <> " is \""
      <> value
      <> "\", which is not a major.minor.patch version"
  }
}

fn describe_parse_error(error: tom.ParseError) -> ConfigError {
  case error {
    tom.Unexpected(got:, expected:) -> InvalidToml(got:, expected:)
    tom.KeyAlreadyInUse(key:) -> RepeatedKey(string.join(key, "."))
  }
}

fn required_string(
  table: Dict(String, Toml),
  key: List(String),
  missing: ConfigError,
) -> Result(String, ConfigError) {
  tom.get_string(table, key)
  |> result.map_error(required_error(_, missing))
}

fn required_error(error: tom.GetError, missing: ConfigError) -> ConfigError {
  case error {
    tom.NotFound(key: _) -> missing
    tom.WrongType(key:, expected: _, got:) ->
      WrongSettingType(string.join(key, "."), "a string", got)
  }
}

fn read_repository(
  document: Dict(String, Toml),
) -> Result(check.GitHubRepository, ConfigError) {
  use repository_type <- result.try(required_string(
    document,
    ["repository", "type"],
    RepositoryNotFound,
  ))
  use Nil <- result.try(require_github(repository_type))
  use owner <- result.try(required_string(
    document,
    ["repository", "user"],
    RepositoryNotFound,
  ))
  use name <- result.try(required_string(
    document,
    ["repository", "repo"],
    RepositoryNotFound,
  ))
  Ok(GitHubRepository(owner:, name:))
}

fn require_github(repository_type: String) -> Result(Nil, ConfigError) {
  case repository_type {
    "github" -> Ok(Nil)
    _ -> Error(UnsupportedRepository(repository_type))
  }
}

fn read_settings(
  document: Dict(String, Toml),
) -> Result(Dict(String, Toml), ConfigError) {
  use found <- result.try(
    tom.get_table(document, ["tools", "dream_snippets"])
    |> optional_value(settings_key, "a table"),
  )
  let settings = option.unwrap(found, dict.new())
  case list.find(dict.keys(settings), is_unknown_setting) {
    Ok(key) -> Error(UnknownSetting(key))
    Error(Nil) -> Ok(settings)
  }
}

fn is_unknown_setting(key: String) -> Bool {
  !list.contains(known_settings, key)
}

/// A value that may be missing: `None` when it is missing, and an error
/// when it has the wrong type.
fn optional_value(
  found: Result(a, tom.GetError),
  key: String,
  expected: String,
) -> Result(Option(a), ConfigError) {
  case found {
    Ok(value) -> Ok(Some(value))
    Error(tom.NotFound(key: _)) -> Ok(None)
    Error(tom.WrongType(key: _, expected: _, got:)) ->
      Error(WrongSettingType(key:, expected:, found: got))
  }
}

fn optional_string(
  settings: Dict(String, Toml),
  key: String,
) -> Result(Option(String), ConfigError) {
  tom.get_string(settings, [key])
  |> optional_value(settings_key <> "." <> key, "a string")
}

fn read_badge_guide(
  settings: Dict(String, Toml),
) -> Result(String, ConfigError) {
  use found <- result.map(optional_string(settings, "badge_guide"))
  option.unwrap(found, default_badge_guide)
}

fn read_release_notes_guide(
  settings: Dict(String, Toml),
) -> Result(String, ConfigError) {
  use found <- result.map(optional_string(settings, "release_notes_guide"))
  option.unwrap(found, default_release_notes_guide)
}

/// Reads a setting that is a list of paths, such as `guides`, or its
/// default when it is not set.
fn read_path_list(
  settings: Dict(String, Toml),
  setting: String,
  default: List(String),
) -> Result(List(String), ConfigError) {
  let key = settings_key <> "." <> setting
  use found <- result.try(
    tom.get_array(settings, [setting])
    |> optional_value(key, "an array of strings"),
  )
  case found {
    None -> Ok(default)
    Some(items) -> list.try_map(items, fn(item) { string_item(item, key) })
  }
}

/// The keys of the `[dependencies]` and `[dev-dependencies]` tables, in
/// that order. A missing table has no keys.
fn read_dependency_names(
  document: Dict(String, Toml),
) -> Result(List(String), ConfigError) {
  ["dependencies", "dev-dependencies"]
  |> list.try_map(fn(table) {
    tom.get_table(document, [table])
    |> optional_value(table, "a table")
    |> result.map(fn(found) {
      found
      |> option.map(fn(entries) {
        list.sort(dict.keys(entries), string.compare)
      })
      |> option.unwrap([])
    })
  })
  |> result.map(list.flatten)
}

fn string_item(item: Toml, key: String) -> Result(String, ConfigError) {
  case item {
    tom.String(text) -> Ok(text)
    _ -> Error(RootNotAString(key))
  }
}

fn read_checked_from_version(
  settings: Dict(String, Toml),
) -> Result(Version, ConfigError) {
  use found <- result.try(optional_string(settings, "checked_from_version"))
  case found {
    None -> Ok(default_checked_from_version)
    Some(text) ->
      check.parse_release_version(text)
      |> result.replace_error(InvalidCheckedFromVersion(text))
  }
}

fn read_roots(
  settings: Dict(String, Toml),
) -> Result(List(CheckedRoot), ConfigError) {
  root_settings
  |> list.try_map(fn(setting) { read_root_setting(settings, setting) })
  |> result.map(list.flatten)
}

fn read_root_setting(
  settings: Dict(String, Toml),
  setting: #(String, DocumentKind),
) -> Result(List(CheckedRoot), ConfigError) {
  let #(key, kind) = setting
  let dotted_key = settings_key <> "." <> key
  use found <- result.try(
    tom.get_array(settings, [key])
    |> optional_value(dotted_key, "an array of strings"),
  )
  case found {
    None -> Ok(list.filter(default_roots(), fn(root) { root.kind == kind }))
    Some(items) ->
      list.try_map(items, fn(item) { configured_root(item, dotted_key, kind) })
  }
}

fn configured_root(
  item: Toml,
  key: String,
  kind: DocumentKind,
) -> Result(CheckedRoot, ConfigError) {
  case item {
    tom.String(path) -> Ok(CheckedRoot(path:, kind:, presence: MustExist))
    _ -> Error(RootNotAString(key))
  }
}
