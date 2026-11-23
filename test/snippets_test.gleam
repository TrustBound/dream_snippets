//// Tests for the code blocks in the README and in the doc comments.

import dream_snippets/check.{
  Changelog, GitHubRepository, GleamSource, MarkdownDocument,
  MissingBadgeHeading, Problem, Project, ReleaseNotes, Report, Version,
}
import dream_snippets/config.{CheckedRoot, Config, MayBeMissing}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, group, it}
import fixtures/project
import snippets/doc_check_project
import snippets/doc_parse_config
import snippets/guide_check_markdown

pub fn tests() -> TestSuite {
  describe("snippets", [
    group("guide_check_markdown.check_guide", [
      it("finds a gleam block with no badge heading", fn() {
        // Arrange
        let guide = "Some prose.\n\n```gleam\nx\n```\n"

        // Act
        let report = guide_check_markdown.check_guide(guide)

        // Assert
        report
        |> should
        |> be_equal(
          Report(blocks_checked: 1, diff_blocks_checked: 0, problems: [
            Problem("docs/guide.md", 3, MissingBadgeHeading),
          ]),
        )
        |> or_fail_with("The block should fail for its missing heading")
      }),
    ]),
    group("doc_parse_config.read_config", [
      it("reads the project, the default roots and the version", fn() {
        // Act
        let parsed = doc_parse_config.read_config()

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
            checked_from_version: Version(1, 0, 0),
          )),
        )
        |> or_fail_with("The configuration should be read")
      }),
    ]),
    group("doc_check_project.summary_of", [
      it("returns the summary line of a project with no problem", fn() {
        // Arrange
        let assert Ok(directory) =
          project.write_project("snippet_summary", [
            #(
              "gleam.toml",
              "name = \"my_app\"\nversion = \"1.2.0\"\nrepository = { type = \"github\", user = \"me\", repo = \"my_app\" }\n",
            ),
            #("README.md", "# My app\n"),
          ])

        // Act
        let lines = doc_check_project.summary_of(directory)

        // Assert
        lines
        |> should
        |> be_equal([
          "0 blocks and 0 diff blocks checked in 1 files, 0 problems",
        ])
        |> or_fail_with("The summary should count one file")
      }),
    ]),
  ])
}
