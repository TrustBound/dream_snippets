//// Tests for the code blocks in the README and in the doc comments.

import dream_snippets.{Output}
import dream_snippets/check.{
  AlphanumericIdentifier, Changelog, CompareLink, DiffHunk, ExampleHeading,
  GitHubRepository, GleamSource, GuideBadgeLink, GuideLink, LineRange,
  MarkdownDocument, MissingBadgeHeading, MissingGuideBadge, MissingReleaseDate,
  MissingReleaseNotesChoice, MissingReleaseNotesSection, NumericIdentifier,
  Problem, Project, ReleaseNotes, Report, SnippetLink, UnclosedFence, Version,
}
import dream_snippets/config.{CheckedRoot, Config, MayBeMissing}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, group, it}
import fixtures/project
import gleam/option.{Some}
import gleam/order
import simplifile
import snippets/doc_add_report
import snippets/doc_changelog_section_name
import snippets/doc_check_changelog
import snippets/doc_check_gleam_source
import snippets/doc_check_project
import snippets/doc_check_readme
import snippets/doc_check_release_notes
import snippets/doc_check_release_notes_template
import snippets/doc_classify_fence
import snippets/doc_compare_versions
import snippets/doc_default_roots
import snippets/doc_describe_check_error
import snippets/doc_describe_config_error
import snippets/doc_describe_git_error
import snippets/doc_describe_problem
import snippets/doc_describe_reason
import snippets/doc_diff_between_tags
import snippets/doc_diff_from_tag
import snippets/doc_empty_report
import snippets/doc_file_at_tag
import snippets/doc_heading_anchors
import snippets/doc_heading_slug
import snippets/doc_is_checked_changelog_section
import snippets/doc_is_checked_release_notes
import snippets/doc_is_guide_path
import snippets/doc_is_safe_path
import snippets/doc_is_safe_tag
import snippets/doc_is_tested_file
import snippets/doc_looks_like_gleam
import snippets/doc_one_line
import snippets/doc_output
import snippets/doc_parse_badge_heading
import snippets/doc_parse_compare_link
import snippets/doc_parse_config
import snippets/doc_parse_diff_badge_heading
import snippets/doc_parse_example_heading
import snippets/doc_parse_guide_link
import snippets/doc_parse_hunks
import snippets/doc_parse_line_selection
import snippets/doc_parse_old_code_heading
import snippets/doc_parse_release_version
import snippets/doc_parse_snippet_link
import snippets/doc_path_digest
import snippets/doc_release_notes_version
import snippets/doc_release_requirement
import snippets/doc_repository_url
import snippets/doc_run_git
import snippets/doc_sort_problems
import snippets/doc_summary
import snippets/doc_tag_exists
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
          Report(
            ..check.empty_report(),
            blocks_checked: 1,
            diff_blocks_checked: 0,
            problems: [
              Problem("docs/guide.md", 3, MissingBadgeHeading),
            ],
          ),
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
              tested_files: ["test", ".github"],
              dependencies: [],
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
            checked_from_version: Version(1, 0, 0, []),
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
          "0 blocks and 0 diff blocks checked in 1 file, 0 problems; 0 file blocks, 0 command blocks and 0 output blocks checked; 0 illustration blocks",
        ])
        |> or_fail_with("The summary should count one file")
      }),
    ]),
    group("doc_output.output_of_missing_root", [
      it("prints the error on standard error with exit status 1", fn() {
        // Act
        let result = doc_output.output_of_missing_root()

        // Assert
        result
        |> should
        |> be_equal(Output(
          standard_output: [],
          standard_error: [
            "error: docs is set in [tools.dream_snippets] in gleam.toml, but it does not exist",
          ],
          exit_status: 1,
        ))
        |> or_fail_with("The error should be one line on standard error")
      }),
    ]),
    group("doc_describe_check_error.missing_root_message", [
      it("names the missing root", fn() {
        // Act
        let result = doc_describe_check_error.missing_root_message()

        // Assert
        result
        |> should
        |> be_equal(
          "examples is set in [tools.dream_snippets] in gleam.toml, but it does not exist",
        )
        |> or_fail_with("The message should name the root")
      }),
    ]),
    group("doc_is_checked_release_notes.checked_release_notes", [
      it("checks only release notes from 2.0.0 on", fn() {
        // Act
        let result = doc_is_checked_release_notes.checked_release_notes()

        // Assert
        result
        |> should
        |> be_equal([True, False, False])
        |> or_fail_with("Only 10.0.0 should be checked")
      }),
    ]),
    group("doc_release_notes_version.version_of_release_notes", [
      it("reads 3.0.0 from the file name", fn() {
        // Act
        let result = doc_release_notes_version.version_of_release_notes()

        // Assert
        result
        |> should
        |> be_equal(Ok(Version(3, 0, 0, [])))
        |> or_fail_with("The version should be 3.0.0")
      }),
    ]),
    group("doc_parse_release_version.release_candidate_version", [
      it("reads the pre-release part", fn() {
        // Act
        let result = doc_parse_release_version.release_candidate_version()

        // Assert
        result
        |> should
        |> be_equal(
          Ok(
            Version(3, 1, 0, [
              AlphanumericIdentifier("rc"),
              NumericIdentifier(1),
            ]),
          ),
        )
        |> or_fail_with("The version should be 3.1.0-rc.1")
      }),
    ]),
    group("doc_compare_versions.compare_release_candidate", [
      it("puts 2.0.0-rc.1 before 2.0.0", fn() {
        // Act
        let result = doc_compare_versions.compare_release_candidate()

        // Assert
        result
        |> should
        |> be_equal(order.Lt)
        |> or_fail_with("2.0.0-rc.1 should come before 2.0.0")
      }),
    ]),
    group("doc_one_line.visible_line_break", [
      it("writes the line break as a backslash and an n", fn() {
        // Act
        let result = doc_one_line.visible_line_break()

        // Assert
        result
        |> should
        |> be_equal("found \\n where \" was expected")
        |> or_fail_with("The message should be one line")
      }),
    ]),
    group("doc_check_changelog.check_my_changelog", [
      it("checks the Unreleased section only", fn() {
        // Act
        let result = doc_check_changelog.check_my_changelog()

        // Assert
        result
        |> should
        |> be_equal(
          Report(
            ..check.empty_report(),
            blocks_checked: 1,
            diff_blocks_checked: 0,
            problems: [
              Problem("CHANGELOG.md", 5, MissingBadgeHeading),
            ],
          ),
        )
        |> or_fail_with("The 0.9.0 section should be left out")
      }),
    ]),
    group("doc_changelog_section_name.section_name", [
      it("reads the version of the heading", fn() {
        // Act
        let result = doc_changelog_section_name.section_name()

        // Assert
        result
        |> should
        |> be_equal(Ok("3.0.0"))
        |> or_fail_with("The name should be 3.0.0")
      }),
    ]),
    group("doc_is_checked_changelog_section.checked_sections", [
      it("leaves out the sections before 1.0.0", fn() {
        // Act
        let result = doc_is_checked_changelog_section.checked_sections()

        // Assert
        result
        |> should
        |> be_equal([True, False, True])
        |> or_fail_with("Only 0.9.0 should be left out")
      }),
    ]),
    group("doc_check_release_notes_template.check_my_release_notes", [
      it("finds the missing Community section", fn() {
        // Act
        let result = doc_check_release_notes_template.check_my_release_notes()

        // Assert
        result
        |> should
        |> be_equal([
          Problem(
            "releases/release-1.2.0.md",
            1,
            MissingReleaseNotesSection("Community"),
          ),
        ])
        |> or_fail_with("Community should be missing")
      }),
    ]),
    group("doc_sort_problems.sorted_problems", [
      it("sorts by file, then by line", fn() {
        // Act
        let result = doc_sort_problems.sorted_problems()

        // Assert
        result
        |> should
        |> be_equal([
          Problem("CHANGELOG.md", 4, UnclosedFence),
          Problem("README.md", 2, MissingReleaseDate),
          Problem("README.md", 9, MissingBadgeHeading),
        ])
        |> or_fail_with("The problems should be sorted")
      }),
    ]),
    group("doc_summary.summary_line", [
      it("counts the blocks, files and problems", fn() {
        // Act
        let result = doc_summary.summary_line()

        // Assert
        result
        |> should
        |> be_equal(
          "12 blocks and 2 diff blocks checked in 9 files, 1 problem; 0 file blocks, 1 command block and 4 output blocks checked; 0 illustration blocks",
        )
        |> or_fail_with("The summary should give each count")
      }),
    ]),
    group("doc_describe_problem.problem_line", [
      it("gives the file, the line and the reason", fn() {
        // Act
        let result = doc_describe_problem.problem_line()

        // Assert
        result
        |> should
        |> be_equal("README.md:14: this code fence has no closing fence")
        |> or_fail_with("The line should start with the file and line")
      }),
    ]),
    group("doc_repository_url.dream_url", [
      it("gives the GitHub address", fn() {
        // Act
        let result = doc_repository_url.dream_url()

        // Assert
        result
        |> should
        |> be_equal("https://github.com/TrustBound/dream")
        |> or_fail_with("The address should be on GitHub")
      }),
    ]),
    group("doc_describe_reason.wrong_tag_reason", [
      it("names both tags", fn() {
        // Act
        let result = doc_describe_reason.wrong_tag_reason()

        // Assert
        result
        |> should
        |> be_equal(
          "the badge link uses the tag 1.1.0, but this file must link at the tag 1.2.0 (the docs of my_app use the version in gleam.toml)",
        )
        |> or_fail_with("The reason should name both tags")
      }),
    ]),
    group("doc_check_readme.check_my_readme", [
      it("finds the missing guide badge", fn() {
        // Act
        let result = doc_check_readme.check_my_readme()

        // Assert
        result
        |> should
        |> be_equal(
          Report(
            ..check.empty_report(),
            blocks_checked: 1,
            diff_blocks_checked: 0,
            problems: [
              Problem("README.md", 3, MissingGuideBadge),
            ],
          ),
        )
        |> or_fail_with("The heading should need a guide badge")
      }),
    ]),
    group("doc_check_gleam_source.check_my_source", [
      it("finds a doc comment block with no badge heading", fn() {
        // Act
        let result = doc_check_gleam_source.check_my_source()

        // Assert
        result
        |> should
        |> be_equal(
          Report(
            ..check.empty_report(),
            blocks_checked: 1,
            diff_blocks_checked: 0,
            problems: [
              Problem("src/app.gleam", 3, MissingBadgeHeading),
            ],
          ),
        )
        |> or_fail_with("The doc comment block should fail")
      }),
    ]),
    group("doc_parse_badge_heading.badge_address", [
      it("returns the snippet address", fn() {
        // Act
        let result = doc_parse_badge_heading.badge_address()

        // Assert
        result
        |> should
        |> be_equal(Ok(
          "https://github.com/me/my_app/blob/1.2.0/test/snippets/hello.gleam",
        ))
        |> or_fail_with("The address should be read")
      }),
    ]),
    group("doc_parse_diff_badge_heading.diff_badge_address", [
      it("returns the compare address", fn() {
        // Act
        let result = doc_parse_diff_badge_heading.diff_badge_address()

        // Assert
        result
        |> should
        |> be_equal(Ok(
          "https://github.com/me/my_app/compare/1.1.0...1.2.0#diff-"
          <> "8b96d7e46c8e7f38e04701586133706ffc625db241b80e9c73922c10b89804f8",
        ))
        |> or_fail_with("The address should be read")
      }),
    ]),
    group("doc_parse_example_heading.example_heading", [
      it("returns both badge addresses and the guide badge name", fn() {
        // Act
        let result = doc_parse_example_heading.example_heading()

        // Assert
        result
        |> should
        |> be_equal(
          Ok(ExampleHeading(
            snippet_address: "https://github.com/me/my_app/blob/1.2.0/test/snippets/hello.gleam",
            guide_badge: GuideBadgeLink(
              address: "https://github.com/me/my_app/blob/1.2.0/docs/guides/hello.md#say-hello",
              alt: "Guide: Hello",
              title: Some("Guide: Hello"),
            ),
          )),
        )
        |> or_fail_with("Both badges should be read")
      }),
    ]),
    group("doc_parse_guide_link.guide_link", [
      it("reads the tag, the path and the anchor", fn() {
        // Act
        let result = doc_parse_guide_link.guide_link()

        // Assert
        result
        |> should
        |> be_equal(
          Ok(GuideLink(
            tag: "1.2.0",
            path: "docs/guides/hello.md",
            anchor: "say-hello",
          )),
        )
        |> or_fail_with("The guide link should be read")
      }),
    ]),
    group("doc_parse_snippet_link.snippet_link", [
      it("reads the tag, the path and the line anchor", fn() {
        // Act
        let result = doc_parse_snippet_link.snippet_link()

        // Assert
        result
        |> should
        |> be_equal(
          Ok(SnippetLink(
            tag: "1.2.0",
            path: "test/snippets/hello.gleam",
            anchor: "#L3-L5",
          )),
        )
        |> or_fail_with("The snippet link should be read")
      }),
    ]),
    group("doc_parse_line_selection.line_range", [
      it("reads lines 3 to 5", fn() {
        // Act
        let result = doc_parse_line_selection.line_range()

        // Assert
        result
        |> should
        |> be_equal(Ok(LineRange(start: 3, end: 5)))
        |> or_fail_with("The range should be 3 to 5")
      }),
    ]),
    group("doc_classify_fence.fence_kinds", [
      it("gives the kind of each info string", fn() {
        // Act
        let result = doc_classify_fence.fence_kinds()

        // Assert
        result
        |> should
        |> be_equal([
          check.GleamBlock,
          check.CommandBlock("sh"),
          check.OutputBlock,
          check.IllustrationBlock("text"),
          check.FileBlock("yaml"),
          check.UnlabelledBlock,
        ])
        |> or_fail_with("Each info string should give its kind")
      }),
    ]),
    group("doc_is_tested_file.tested_paths", [
      it("accepts the tested files and the files under them", fn() {
        // Act
        let result = doc_is_tested_file.tested_paths()

        // Assert
        result
        |> should
        |> be_equal([True, True, False])
        |> or_fail_with("Only the tested files should be accepted")
      }),
    ]),
    group("doc_release_requirement.requirement", [
      it("writes the range up to the next major version", fn() {
        // Act
        let result = doc_release_requirement.requirement()

        // Assert
        result
        |> should
        |> be_equal(">= 2.1.0-rc.1 and < 3.0.0")
        |> or_fail_with("The requirement should end at the next major")
      }),
    ]),
    group("doc_add_report.two_reports", [
      it("adds the counts of both reports", fn() {
        // Act
        let result = doc_add_report.two_reports()

        // Assert
        result
        |> should
        |> be_equal(
          check.Report(
            blocks_checked: 2,
            diff_blocks_checked: 0,
            file_blocks_checked: 0,
            command_blocks_checked: 0,
            output_blocks_checked: 1,
            illustration_blocks: 0,
            problems: [],
          ),
        )
        |> or_fail_with("The counts should be added")
      }),
    ]),
    group("doc_empty_report.no_problems", [
      it("counts no block", fn() {
        // Act
        let result = doc_empty_report.no_problems()

        // Assert
        result
        |> should
        |> be_equal(0)
        |> or_fail_with("An empty report should count no block")
      }),
    ]),
    group("doc_is_guide_path.guide_paths", [
      it("accepts only .md files under the guides", fn() {
        // Act
        let result = doc_is_guide_path.guide_paths()

        // Assert
        result
        |> should
        |> be_equal([True, False, False])
        |> or_fail_with("Only the first path should be a guide")
      }),
    ]),
    group("doc_heading_anchors.anchors", [
      it("adds -1 to a repeated anchor", fn() {
        // Act
        let result = doc_heading_anchors.anchors()

        // Assert
        result
        |> should
        |> be_equal(["my-app", "usage", "usage-1"])
        |> or_fail_with("The second Usage should get -1")
      }),
    ]),
    group("doc_heading_slug.anchor", [
      it("removes the backticks", fn() {
        // Act
        let result = doc_heading_slug.anchor()

        // Assert
        result
        |> should
        |> be_equal("the-requestbody-type")
        |> or_fail_with("The anchor should have no backticks")
      }),
    ]),
    group("doc_parse_compare_link.compare_link", [
      it("reads both tags and the digest", fn() {
        // Act
        let result = doc_parse_compare_link.compare_link()

        // Assert
        result
        |> should
        |> be_equal(
          Ok(CompareLink(
            old_tag: "1.1.0",
            new_tag: "1.2.0",
            anchor_digest: "8b96d7e46c8e7f38e04701586133706ffc625db241b80e9c73922c10b89804f8",
          )),
        )
        |> or_fail_with("The compare link should be read")
      }),
    ]),
    group("doc_is_safe_tag.safe_tags", [
      it("accepts only the version tag", fn() {
        // Act
        let result = doc_is_safe_tag.safe_tags()

        // Assert
        result
        |> should
        |> be_equal([True, False, False])
        |> or_fail_with("Only 1.2.0 should be safe")
      }),
    ]),
    group("doc_is_safe_path.safe_paths", [
      it("accepts only the path inside the repository", fn() {
        // Act
        let result = doc_is_safe_path.safe_paths()

        // Assert
        result
        |> should
        |> be_equal([True, False, False])
        |> or_fail_with("Only src/app.gleam should be safe")
      }),
    ]),
    group("doc_path_digest.digest", [
      it("returns the SHA-256 hex digest", fn() {
        // Act
        let result = doc_path_digest.digest()

        // Assert
        result
        |> should
        |> be_equal(
          "8b96d7e46c8e7f38e04701586133706ffc625db241b80e9c73922c10b89804f8",
        )
        |> or_fail_with("The digest should be the SHA-256 of the path")
      }),
    ]),
    group("doc_parse_hunks.hunks", [
      it("returns one hunk with its lines", fn() {
        // Act
        let result = doc_parse_hunks.hunks()

        // Assert
        result
        |> should
        |> be_equal([
          DiffHunk(header: "@@ -1,3 +1,3 @@", lines: [
            " pub fn name() {",
            "-  \"old\"",
            "+  \"new\"",
            " }",
          ]),
        ])
        |> or_fail_with("The diff should have one hunk")
      }),
    ]),
    group("doc_looks_like_gleam.gleam_lines", [
      it("finds the import and the function", fn() {
        // Act
        let result = doc_looks_like_gleam.gleam_lines()

        // Assert
        result
        |> should
        |> be_equal([True, False, True])
        |> or_fail_with("npm install should not look like Gleam")
      }),
    ]),
    group("doc_default_roots.default_paths", [
      it("lists the seven default paths", fn() {
        // Act
        let result = doc_default_roots.default_paths()

        // Assert
        result
        |> should
        |> be_equal([
          "README.md",
          "SECURITY.md",
          "docs",
          "examples",
          "CHANGELOG.md",
          "releases",
          "src",
        ])
        |> or_fail_with("The default paths should be listed in order")
      }),
    ]),
    group("doc_describe_config_error.name_not_found_message", [
      it("says that the name is missing", fn() {
        // Act
        let result = doc_describe_config_error.name_not_found_message()

        // Assert
        result
        |> should
        |> be_equal(
          "gleam.toml has no name = \"...\" line before its first [section]",
        )
        |> or_fail_with("The message should name the missing key")
      }),
    ]),
    group("doc_describe_git_error.git_failure_message", [
      it("gives the exit status", fn() {
        // Act
        let result = doc_describe_git_error.git_failure_message()

        // Assert
        result
        |> should
        |> be_equal("git stopped with exit status 128")
        |> or_fail_with("The message should give the status")
      }),
    ]),
    group("doc_tag_exists.has_first_release", [
      it("finds the tag 1.0.0", fn() {
        // Arrange
        let assert Ok(directory) =
          project.write_project("snippet_tag_exists", [
            #("src/app.gleam", "pub const name = \"app\"\n"),
          ])
        let assert Ok(Nil) = project.commit_and_tag(directory, "1.0.0")

        // Act
        let result = doc_tag_exists.has_first_release(directory)

        // Assert
        result
        |> should
        |> be_equal(Ok(True))
        |> or_fail_with("The tag should be found")
      }),
    ]),
    group("doc_diff_from_tag.changes_since_first_release", [
      it("returns an empty diff for a file with no change", fn() {
        // Arrange
        let assert Ok(directory) =
          project.write_project("snippet_diff_from_tag", [
            #("src/app.gleam", "pub const name = \"app\"\n"),
          ])
        let assert Ok(Nil) = project.commit_and_tag(directory, "1.0.0")

        // Act
        let result = doc_diff_from_tag.changes_since_first_release(directory)

        // Assert
        result
        |> should
        |> be_equal(Ok(""))
        |> or_fail_with("The diff should be empty")
      }),
    ]),
    group("doc_diff_between_tags.changes_in_second_release", [
      it("returns an empty diff for a file with no change", fn() {
        // Arrange
        let assert Ok(directory) =
          project.write_project("snippet_diff_between_tags", [
            #("src/app.gleam", "pub const name = \"app\"\n"),
            #("README.md", "# app\n"),
          ])
        let assert Ok(Nil) = project.commit_and_tag(directory, "1.0.0")
        let assert Ok(Nil) =
          simplifile.write(to: directory <> "/README.md", contents: "# App\n")
        let assert Ok(Nil) = project.commit_again_and_tag(directory, "1.1.0")

        // Act
        let result = doc_diff_between_tags.changes_in_second_release(directory)

        // Assert
        result
        |> should
        |> be_equal(Ok(""))
        |> or_fail_with("The diff should be empty")
      }),
    ]),
    group("doc_file_at_tag.app_at_first_release", [
      it("reads the file at the tag 1.0.0", fn() {
        // Arrange
        let assert Ok(directory) =
          project.write_project("snippet_file_at_tag", [
            #("src/app.gleam", "pub const name = \"app\"\n"),
          ])
        let assert Ok(Nil) = project.commit_and_tag(directory, "1.0.0")

        // Act
        let result = doc_file_at_tag.app_at_first_release(directory)

        // Assert
        result
        |> should
        |> be_equal(Ok(Some("pub const name = \"app\"\n")))
        |> or_fail_with("The file at the tag should be read")
      }),
    ]),
    group("doc_parse_old_code_heading.old_code_link", [
      it("reads the link of the badge", fn() {
        // Act
        let result = doc_parse_old_code_heading.old_code_link()

        // Assert
        result
        |> should
        |> be_equal(
          Ok(SnippetLink(tag: "1.1.0", path: "src/app.gleam", anchor: "#L3-L5")),
        )
        |> or_fail_with("The tag, the path and the anchor should be read")
      }),
    ]),
    group("doc_check_release_notes.check_my_release_notes", [
      it("passes the old code block and finds the missing sections", fn() {
        // Arrange
        let file = "releases/release-1.2.0.md"

        // Act
        let report = doc_check_release_notes.check_my_release_notes()

        // Assert
        report
        |> should
        |> be_equal(
          Report(
            ..check.empty_report(),
            blocks_checked: 1,
            diff_blocks_checked: 0,
            problems: [
              Problem(file, 1, MissingReleaseNotesSection("Key Highlights")),
              Problem(file, 1, MissingReleaseNotesSection("What's New")),
              Problem(file, 1, MissingReleaseNotesSection("Testing")),
              Problem(
                file,
                1,
                MissingReleaseNotesChoice(["Upgrading", "Installing"]),
              ),
              Problem(file, 1, MissingReleaseNotesSection("Documentation")),
              Problem(file, 1, MissingReleaseNotesSection("Community")),
            ],
          ),
        )
        |> or_fail_with("Only the template problems should be found")
      }),
    ]),
    group("doc_run_git.list_tags", [
      it("lists the one tag", fn() {
        // Arrange
        let assert Ok(directory) =
          project.write_project("snippet_run_git", [
            #("src/app.gleam", "pub const name = \"app\"\n"),
          ])
        let assert Ok(Nil) = project.commit_and_tag(directory, "1.0.0")

        // Act
        let result = doc_run_git.list_tags(directory)

        // Assert
        result
        |> should
        |> be_equal(Ok("1.0.0\n"))
        |> or_fail_with("git should list the tag")
      }),
    ]),
  ])
}
