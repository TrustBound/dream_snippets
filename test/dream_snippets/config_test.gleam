//// Tests for `dream_snippets/config`, which reads the project and the
//// settings of the check from the text of `gleam.toml`.

import dream_snippets/check.{
  Changelog, GitHubRepository, GleamSource, MarkdownDocument, Project,
  ReleaseNotes, Version,
}
import dream_snippets/config.{
  CheckedRoot, Config, InvalidCheckedFromVersion, InvalidToml, MayBeMissing,
  MustExist, NameNotFound, RepeatedKey, RepositoryNotFound, RootNotAString,
  UnknownSetting, UnsupportedRepository, VersionNotFound, WrongSettingType,
}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{type UnitNode, describe, group, it}
import gleam/list
import gleam/result

const project_lines =
  "name = \"my_app\"
version = \"1.2.0\"
repository = { type = \"github\", user = \"me\", repo = \"my_app\" }
"

pub fn tests() -> TestSuite {
  describe("dream_snippets/config", [
    parse_tests(),
    parse_error_tests(),
    describe_error_tests(),
  ])
}

fn parse_tests() -> UnitNode {
  group("parse", [
    it("reads dream's defaults when there is no settings table", fn() {
      // Arrange
      let gleam_toml =
        "name = \"dream\"
version = \"3.0.0\"
repository = { type = \"github\", user = \"TrustBound\", repo = \"dream\" }

[dependencies]
version = \"9\"
"

      // Act
      let parsed = config.parse(gleam_toml)

      // Assert
      parsed
      |> should
      |> be_equal(
        Ok(Config(
          project: Project(
            name: "dream",
            version: "3.0.0",
            repository: GitHubRepository(owner: "TrustBound", name: "dream"),
            badge_guide: "https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html",
            release_notes_guide: "https://hexdocs.pm/dream_snippets/guides/release-notes-template.html",
            guides: ["docs/guides"],
            tested_files: ["test", ".github"],
            dependencies: ["version"],
          ),
          roots: [
            CheckedRoot("README.md", MarkdownDocument, MayBeMissing),
            CheckedRoot("SECURITY.md", MarkdownDocument, MayBeMissing),
            CheckedRoot("docs", MarkdownDocument, MayBeMissing),
            CheckedRoot("examples", MarkdownDocument, MayBeMissing),
            CheckedRoot("CHANGELOG.md", Changelog, MayBeMissing),
            CheckedRoot("releases", ReleaseNotes, MayBeMissing),
            CheckedRoot("src", GleamSource, MayBeMissing),
          ],
          checked_from_version: Version(0, 0, 0, []),
        )),
      )
      |> or_fail_with(
        "The defaults should be dream's places, 0.0.0 and the HexDocs guide",
      )
    }),
    it("reads every setting of the settings table", fn() {
      // Arrange
      let gleam_toml = project_lines <> "
[tools.dream_snippets]
markdown = [\"README.md\", \"guides\"]
changelog = [\"HISTORY.md\"]
release_notes = []
gleam_source = [\"src\"]
checked_from_version = \"1.0.0\"
badge_guide = \"CONTRIBUTING.md\"
release_notes_guide = \"docs/release-notes.md\"
guides = [\"docs/guides\", \"examples/guides/\"]
"

      // Act
      let parsed = config.parse(gleam_toml)

      // Assert
      parsed
      |> should
      |> be_equal(
        Ok(Config(
          project: Project(
            name: "my_app",
            version: "1.2.0",
            repository: GitHubRepository(owner: "me", name: "my_app"),
            badge_guide: "CONTRIBUTING.md",
            release_notes_guide: "docs/release-notes.md",
            guides: ["docs/guides", "examples/guides/"],
            tested_files: ["test", ".github"],
            dependencies: [],
          ),
          roots: [
            CheckedRoot("README.md", MarkdownDocument, MustExist),
            CheckedRoot("guides", MarkdownDocument, MustExist),
            CheckedRoot("HISTORY.md", Changelog, MustExist),
            CheckedRoot("src", GleamSource, MustExist),
          ],
          checked_from_version: Version(1, 0, 0, []),
        )),
      )
      |> or_fail_with("Each setting should replace its default")
    }),
    it(
      "keeps the defaults of the kinds that the settings table leaves out",
      fn() {
        // Arrange
        let gleam_toml =
          project_lines
          <> "\n[tools.dream_snippets]\nmarkdown = [\"README.md\"]\n"

        // Act
        let parsed = config.parse(gleam_toml)

        // Assert
        parsed
        |> should
        |> be_equal(
          Ok(Config(
            project: Project(
              name: "my_app",
              version: "1.2.0",
              repository: GitHubRepository(owner: "me", name: "my_app"),
              badge_guide: "https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html",
              release_notes_guide: "https://hexdocs.pm/dream_snippets/guides/release-notes-template.html",
              guides: ["docs/guides"],
              tested_files: ["test", ".github"],
              dependencies: [],
            ),
            roots: [
              CheckedRoot("README.md", MarkdownDocument, MustExist),
              CheckedRoot("CHANGELOG.md", Changelog, MayBeMissing),
              CheckedRoot("releases", ReleaseNotes, MayBeMissing),
              CheckedRoot("src", GleamSource, MayBeMissing),
            ],
            checked_from_version: Version(0, 0, 0, []),
          )),
        )
        |> or_fail_with("Only the Markdown roots should change")
      },
    ),
  ])
}

fn parse_error_tests() -> UnitNode {
  group("parse errors", [
    it("fails text that is not TOML", fn() {
      // Act
      let parsed = config.parse("name = ")

      // Assert
      parsed
      |> should
      |> be_equal(Error(InvalidToml(got: "EOF", expected: "value")))
      |> or_fail_with("A key with no value is not TOML")
    }),
    it("fails a key that is set twice", fn() {
      // Act
      let parsed = config.parse("name = \"a\"\nname = \"b\"\n")

      // Assert
      parsed
      |> should
      |> be_equal(Error(RepeatedKey("name")))
      |> or_fail_with("A repeated key should fail")
    }),
    it("fails a file with no name", fn() {
      // Act
      let parsed = config.parse("version = \"1.0.0\"\n")

      // Assert
      parsed
      |> should
      |> be_equal(Error(NameNotFound))
      |> or_fail_with("The name is required")
    }),
    it("fails a file with no version", fn() {
      // Act
      let parsed =
        config.parse("name = \"my_app\"\n\n[dependencies]\nversion = \"9\"\n")

      // Assert
      parsed
      |> should
      |> be_equal(Error(VersionNotFound))
      |> or_fail_with("A version in a section is not the package version")
    }),
    it("fails a version that is not a string", fn() {
      // Act
      let parsed = config.parse("name = \"my_app\"\nversion = 1\n")

      // Assert
      parsed
      |> should
      |> be_equal(
        Error(WrongSettingType(
          key: "version",
          expected: "a string",
          found: "Int",
        )),
      )
      |> or_fail_with("A number is not a version")
    }),
    it("fails a file with no repository", fn() {
      // Act
      let parsed = config.parse("name = \"my_app\"\nversion = \"1.0.0\"\n")

      // Assert
      parsed
      |> should
      |> be_equal(Error(RepositoryNotFound))
      |> or_fail_with("The repository is required")
    }),
    it("fails a repository that is not on GitHub", fn() {
      // Arrange
      let gleam_toml =
        "name = \"a\"\nversion = \"1.0.0\"\nrepository = { type = \"gitlab\", user = \"me\", repo = \"a\" }\n"

      // Act
      let parsed = config.parse(gleam_toml)

      // Assert
      parsed
      |> should
      |> be_equal(Error(UnsupportedRepository("gitlab")))
      |> or_fail_with("Only GitHub repositories are supported")
    }),
    it("fails a GitHub repository with no repo", fn() {
      // Arrange
      let gleam_toml =
        "name = \"a\"\nversion = \"1.0.0\"\nrepository = { type = \"github\", user = \"me\" }\n"

      // Act
      let parsed = config.parse(gleam_toml)

      // Assert
      parsed
      |> should
      |> be_equal(Error(RepositoryNotFound))
      |> or_fail_with("The repo is required")
    }),
    it("fails a settings value that is not a table", fn() {
      // Act
      let parsed =
        config.parse(project_lines <> "tools = { dream_snippets = 1 }\n")

      // Assert
      parsed
      |> should
      |> be_equal(
        Error(WrongSettingType(
          key: "tools.dream_snippets",
          expected: "a table",
          found: "Int",
        )),
      )
      |> or_fail_with("The settings must be a table")
    }),
    it("fails a setting that the check does not know", fn() {
      // Act
      let parsed =
        config.parse(project_lines <> "\n[tools.dream_snippets]\nroots = []\n")

      // Assert
      parsed
      |> should
      |> be_equal(Error(UnknownSetting("roots")))
      |> or_fail_with("An unknown setting should fail")
    }),
    it("fails a root list that is not an array", fn() {
      // Act
      let parsed =
        config.parse(
          project_lines
          <> "\n[tools.dream_snippets]\nmarkdown = \"README.md\"\n",
        )

      // Assert
      parsed
      |> should
      |> be_equal(
        Error(WrongSettingType(
          key: "tools.dream_snippets.markdown",
          expected: "an array of strings",
          found: "String",
        )),
      )
      |> or_fail_with("The roots must be an array")
    }),
    it("fails a root list that holds a value that is not a string", fn() {
      // Act
      let parsed =
        config.parse(
          project_lines <> "\n[tools.dream_snippets]\nchangelog = [1]\n",
        )

      // Assert
      parsed
      |> should
      |> be_equal(Error(RootNotAString("tools.dream_snippets.changelog")))
      |> or_fail_with("Each root must be a string")
    }),
    it("fails a guides setting that is not an array", fn() {
      // Act
      let parsed =
        config.parse(
          project_lines <> "\n[tools.dream_snippets]\nguides = \"docs\"\n",
        )

      // Assert
      parsed
      |> should
      |> be_equal(
        Error(WrongSettingType(
          key: "tools.dream_snippets.guides",
          expected: "an array of strings",
          found: "String",
        )),
      )
      |> or_fail_with("The guides must be an array")
    }),
    it("fails a guides setting that holds a value that is not a string", fn() {
      // Act
      let parsed =
        config.parse(
          project_lines <> "\n[tools.dream_snippets]\nguides = [1]\n",
        )

      // Assert
      parsed
      |> should
      |> be_equal(Error(RootNotAString("tools.dream_snippets.guides")))
      |> or_fail_with("Each guide directory must be a string")
    }),
    it("fails a badge guide that is not a string", fn() {
      // Act
      let parsed =
        config.parse(
          project_lines <> "\n[tools.dream_snippets]\nbadge_guide = true\n",
        )

      // Assert
      parsed
      |> should
      |> be_equal(
        Error(WrongSettingType(
          key: "tools.dream_snippets.badge_guide",
          expected: "a string",
          found: "Bool",
        )),
      )
      |> or_fail_with("The badge guide must be a string")
    }),
    it("fails a release notes guide that is not a string", fn() {
      // Act
      let parsed =
        config.parse(
          project_lines <> "\n[tools.dream_snippets]\nrelease_notes_guide = 1\n",
        )

      // Assert
      parsed
      |> should
      |> be_equal(
        Error(WrongSettingType(
          key: "tools.dream_snippets.release_notes_guide",
          expected: "a string",
          found: "Int",
        )),
      )
      |> or_fail_with("The release notes guide must be a string")
    }),
    it("fails a checked_from_version that is not a version", fn() {
      // Act
      let parsed =
        config.parse(
          project_lines
          <> "\n[tools.dream_snippets]\nchecked_from_version = \"3\"\n",
        )

      // Assert
      parsed
      |> should
      |> be_equal(Error(InvalidCheckedFromVersion("3")))
      |> or_fail_with("3 is not major.minor.patch")
    }),
  ])
}

fn describe_error_tests() -> UnitNode {
  group("describe_error", [
    it("shows a line break in a TOML error in a visible form", fn() {
      // Arrange
      let text = "name = \"my_app\nversion = \"0.2.0\"\n"

      // Act
      let message =
        config.parse(text) |> result.map_error(config.describe_error)

      // Assert
      message
      |> should
      |> be_equal(Error(
        "gleam.toml is not valid TOML: found \\n where \" was expected",
      ))
      |> or_fail_with("The message should stay on one line")
    }),
    it("describes every error in one line", fn() {
      // Arrange
      let errors = [
        InvalidToml(got: "EOF", expected: "value"),
        RepeatedKey("name"),
        VersionNotFound,
        NameNotFound,
        RepositoryNotFound,
        UnsupportedRepository("gitlab"),
        WrongSettingType(key: "version", expected: "a string", found: "Int"),
        RootNotAString("tools.dream_snippets.changelog"),
        UnknownSetting("roots"),
        InvalidCheckedFromVersion("3"),
      ]

      // Act
      let descriptions = list.map(errors, config.describe_error)

      // Assert
      descriptions
      |> should
      |> be_equal([
        "gleam.toml is not valid TOML: found EOF where value was expected",
        "gleam.toml sets the key name twice",
        "gleam.toml has no version = \"...\" line before its first [section]",
        "gleam.toml has no name = \"...\" line before its first [section]",
        "gleam.toml has no repository = { type = \"github\", user = \"...\", repo = \"...\" }",
        "gleam.toml names a gitlab repository; the badges link at GitHub, so the repository type must be github",
        "version in gleam.toml must be a string, but its TOML type is Int",
        "tools.dream_snippets.changelog in gleam.toml must be an array of strings",
        "tools.dream_snippets.roots in gleam.toml is not a setting; the settings are markdown, changelog, release_notes, gleam_source, checked_from_version, guides, badge_guide, release_notes_guide, tested_files",
        "tools.dream_snippets.checked_from_version in gleam.toml is \"3\", which is not a major.minor.patch version",
      ])
      |> or_fail_with("Each error should have its message")
    }),
  ])
}
