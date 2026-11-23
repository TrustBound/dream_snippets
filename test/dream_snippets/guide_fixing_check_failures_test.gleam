//// Tests for the "Fix a failed check" guide
//// (docs/guides/fixing-check-failures.md). Each test describes the
//// problems or errors that the guide shows, with the functions that the
//// command uses, for the example project `my_app` 0.2.0 with no settings,
//// and asserts the exact lines that the guide shows.

import dream_snippets.{InvalidConfig, ListFailed, MissingRoot, ReadFailed}
import dream_snippets/check.{
  type Project, type Reason, BlockDiffers, DiffLineNotFound, EmptyDiffBlock,
  ExampleNotInGuide, FilesAtTag, ForeignDependency, ForeignGuideLink,
  ForeignLink, GitUnavailable, GleamAddWithoutPackage, GuideAnchorNotFound,
  GuideBadgeNotAllowed, HiddenGleamCode, HunkHeaderNotFound, LineRangePastEnd,
  MalformedBadge, MalformedDiffBadge, MalformedGuideBadge, MalformedLineRange,
  MalformedOldCodeBadge, MisnamedReleaseNotes, MissingBadgeHeading,
  MissingCommandBadgeHeading, MissingDiffBadgeHeading, MissingDiffFileHeader,
  MissingFile, MissingFileAtTag, MissingFileBadgeHeading, MissingGuideAnchor,
  MissingGuideBadge, MissingGuideFile, MissingOldTag, MissingOutputBadgeHeading,
  MissingReleaseTag, NoDiffForPath, NotAGuidePath, NotAnOlderRelease,
  NotCompareLink, OldCodeBadgeWithOtherBadge, OldCodeDiffers, OldCodeNotAllowed,
  OldTestedSourceLine, Problem, ReleaseNotBeforeVersion, ReversedLineRange,
  UnclosedFence, UnknownPackage, UnlabelledFence, UnreadableFile,
  UnsafeOldCodeLink, UnsupportedPackageArgument, UntestedFile, WorkingTree,
  WrongDependencyRequirement, WrongDiffAnchor, WrongGuideTag, WrongNewTag,
  WrongTag,
}
import dream_snippets/config
import dream_snippets/git.{GitFailed, GitNotFound}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import fixtures/guide_project
import gleam/list
import gleam/string
import simplifile

const gleam_toml =
  "name = \"my_app\"
version = \"0.2.0\"
repository = { type = \"github\", user = \"me\", repo = \"my_app\" }
"

const guide = "docs/guides/getting-started.md"

const snippet = "test/snippets/guide_getting_started_greeting.gleam"

const upgrading = "docs/guides/upgrading.md"

fn project() -> Project {
  let assert Ok(configuration) = config.parse(gleam_toml)
  configuration.project
}

/// The lines that the command prints for problems in one file.
fn lines(file: String, problems: List(#(Int, Reason))) -> List(String) {
  let project = project()
  list.map(problems, fn(problem) {
    check.describe_problem(Problem(file, problem.0, problem.1), project)
  })
}

/// The line that the command prints for a `gleam.toml` that `config.parse`
/// cannot use.
fn config_error_line(gleam_toml: String) -> String {
  case config.parse(gleam_toml) {
    Ok(_) -> "no error"
    Error(error) ->
      "error: " <> dream_snippets.describe_error(InvalidConfig(error))
  }
}

/// The lines as the command prints them, each with a line break.
fn printed_text(lines: List(String)) -> String {
  string.concat(list.map(lines, fn(line) { line <> "\n" }))
}

pub fn tests() -> TestSuite {
  describe("fix a failed check guide", [
    it("the heading and the badge", fn() {
      // Act
      let printed =
        lines(guide, [
          #(5, MissingBadgeHeading),
          #(5, MalformedBadge),
          #(3, OldTestedSourceLine),
        ])

      // Assert
      printed_text(printed)
      |> should
      |> be_equal(guide_project.output_file("fixing_heading_and_badge"))
      |> or_fail_with("The badge messages should be the guide's")
    }),
    it("the badge link", fn() {
      // Act
      let printed =
        lines(guide, [
          #(
            5,
            ForeignLink(
              "https://github.com/someone/my_app/blob/0.2.0/" <> snippet,
            ),
          ),
          #(5, WrongTag(found: "0.1.0", expected: "0.2.0")),
          #(5, MissingFile("test/snippets/greeting.gleam")),
          #(5, UnreadableFile(snippet, simplifile.Eacces)),
        ])

      // Assert
      printed_text(printed)
      |> should
      |> be_equal(guide_project.output_file("fixing_badge_link"))
      |> or_fail_with("The link messages should be the guide's")
    }),
    it("the badge link: links that are not blob links of the repository", fn() {
      // Arrange
      let addresses = [
        "https://github.com/someone/my_app/blob/0.2.0/" <> snippet,
        "../test/snippets/guide_getting_started_greeting.gleam",
        "https://github.com/me/my_app/tree/0.2.0/" <> snippet,
        "https://github.com/me/my_app/blob/0.2.0/../" <> snippet,
      ]

      // Act
      let results =
        list.map(addresses, fn(address) {
          check.parse_snippet_link(address, project().repository)
        })

      // Assert
      results
      |> should
      |> be_equal(
        list.map(addresses, fn(address) { Error(ForeignLink(address)) }),
      )
      |> or_fail_with("Each address should be a foreign link")
    }),
    it("the line range", fn() {
      // Act
      let printed =
        lines(guide, [
          #(5, MalformedLineRange("#L5:L9")),
          #(5, ReversedLineRange(start: 9, end: 5)),
          #(5, LineRangePastEnd(end: 20, line_count: 16)),
        ])

      // Assert
      printed_text(printed)
      |> should
      |> be_equal(guide_project.output_file("fixing_line_range"))
      |> or_fail_with("The line range messages should be the guide's")
    }),
    it("the code", fn() {
      // Act
      let printed =
        lines(guide, [
          #(5, BlockDiffers(snippet, "", 9)),
          #(14, BlockDiffers(snippet, "#L13-L16", 15)),
        ])

      // Assert
      printed_text(printed)
      |> should
      |> be_equal(guide_project.output_file("fixing_code"))
      |> or_fail_with("The code messages should be the guide's")
    }),
    it("the fences", fn() {
      // Act
      let printed =
        lines("docs/guides/usage.md", [
          #(4, HiddenGleamCode("text illustration")),
          #(8, UnlabelledFence),
          #(12, UnclosedFence),
        ])

      // Assert
      printed_text(printed)
      |> should
      |> be_equal(guide_project.output_file("fixing_fences"))
      |> or_fail_with("The fence messages should be the guide's")
    }),
    it("blocks of other languages", fn() {
      // Act
      let printed =
        lines("docs/guides/deploy.md", [
          #(5, MissingFileBadgeHeading("dockerfile")),
          #(12, MissingCommandBadgeHeading("sh")),
          #(18, MissingOutputBadgeHeading),
          #(25, UntestedFile("docs/deploy/Dockerfile", ["test", ".github"])),
        ])

      // Assert
      printed_text(printed)
      |> should
      |> be_equal(guide_project.output_file("fixing_other_blocks"))
      |> or_fail_with("The messages of other blocks should be the guide's")
    }),
    it("packages and dependency lines", fn() {
      // Act
      let printed =
        lines("README.md", [
          #(12, UnknownPackage("gleam_jsn")),
          #(13, UnsupportedPackageArgument("my_app@1")),
          #(14, GleamAddWithoutPackage),
          #(20, ForeignDependency("gleam_json")),
          #(
            21,
            WrongDependencyRequirement(
              package: "my_app",
              found: ">= 0.1.0 and < 1.0.0",
              expected: ">= 0.2.0 and < 1.0.0",
            ),
          ),
        ])

      // Assert
      printed_text(printed)
      |> should
      |> be_equal(guide_project.output_file("fixing_packages"))
      |> or_fail_with("The package messages should be the guide's")
    }),
    it("the guide badge", fn() {
      // Act
      let printed =
        lines("README.md", [
          #(5, MissingGuideBadge),
          #(5, MalformedGuideBadge),
          #(
            5,
            ForeignGuideLink("https://hexdocs.pm/my_app/getting-started.html"),
          ),
          #(5, WrongGuideTag(found: "0.1.0", expected: "0.2.0")),
          #(5, NotAGuidePath("docs/usage.md", ["docs/guides"])),
          #(5, MissingGuideAnchor(guide)),
          #(5, MissingGuideFile("docs/guides/greeting.md")),
          #(5, GuideAnchorNotFound(guide, "greet-a-user")),
          #(5, ExampleNotInGuide(guide, snippet)),
        ])
        |> list.append(lines(guide, [#(3, GuideBadgeNotAllowed)]))

      // Assert
      printed_text(printed)
      |> should
      |> be_equal(guide_project.output_file("fixing_guide_badge"))
      |> or_fail_with("The guide badge messages should be the guide's")
    }),
    it("the diff blocks", fn() {
      // Act
      let printed =
        lines(upgrading, [
          #(19, MissingDiffBadgeHeading),
          #(19, MalformedDiffBadge),
          #(
            19,
            NotCompareLink("https://github.com/me/my_app/compare/0.1.0..0.2.0"),
          ),
          #(19, WrongNewTag(found: "0.1.1", expected: "0.2.0")),
          #(19, MissingDiffFileHeader),
          #(19, EmptyDiffBlock),
          #(
            19,
            WrongDiffAnchor(
              "src/my_app.gleam",
              "#diff-" <> check.path_digest("src/my_app.gleam"),
            ),
          ),
          #(19, MissingOldTag("0.1.0")),
          #(19, GitUnavailable(GitNotFound)),
          #(19, GitUnavailable(GitFailed(status: 128, output: ""))),
          #(19, NoDiffForPath("src/my_app.gleam", "0.1.0", WorkingTree)),
          #(22, HunkHeaderNotFound("@@ -1,4 +1,11 @@")),
          #(24, DiffLineNotFound("src/my_app.gleam", "0.1.0", WorkingTree)),
        ])

      // Assert
      printed_text(printed)
      |> should
      |> be_equal(guide_project.output_file("fixing_diff_blocks"))
      |> or_fail_with("The diff messages should be the guide's")
    }),
    it("the code at an older release", fn() {
      // Act
      let printed =
        lines(upgrading, [
          #(7, MalformedOldCodeBadge),
          #(7, OldCodeBadgeWithOtherBadge),
          #(
            7,
            UnsafeOldCodeLink(
              "v0.1.0~1",
              "test/snippets/guide_upgrading_greet_lucy.gleam",
            ),
          ),
          #(7, NotAnOlderRelease("0.2.0", "0.2.0")),
          #(7, MissingOldTag("0.1.0")),
          #(
            7,
            MissingFileAtTag(
              "test/snippets/guide_upgrading_greet_lucy.gleam",
              "0.1.0",
            ),
          ),
          #(
            7,
            OldCodeDiffers(
              "test/snippets/guide_upgrading_greet_lucy.gleam",
              "#L4",
              "0.1.0",
              8,
            ),
          ),
        ])
        |> list.append(
          lines("README.md", [#(5, OldCodeNotAllowed(["docs/guides"]))]),
        )

      // Assert
      printed_text(printed)
      |> should
      |> be_equal(guide_project.output_file("fixing_old_code"))
      |> or_fail_with("The old code messages should be the guide's")
    }),
    it("the docs of an older release", fn() {
      // Act
      let printed =
        lines("releases/release-0.1.0.md", [
          #(11, WrongTag(found: "0.2.0", expected: "0.1.0")),
          #(11, OldCodeDiffers(snippet, "", "0.1.0", 15)),
          #(11, MissingReleaseTag("0.1.0")),
          #(17, NotAnOlderRelease("0.1.0", "0.1.0")),
          #(23, WrongNewTag(found: "0.2.0", expected: "0.1.0")),
          #(23, NoDiffForPath("src/my_app.gleam", "0.0.1", FilesAtTag("0.1.0"))),
          #(
            28,
            DiffLineNotFound("src/my_app.gleam", "0.0.1", FilesAtTag("0.1.0")),
          ),
        ])
        |> list.append(
          lines("releases/release-0.3.0.md", [
            #(11, ReleaseNotBeforeVersion("0.3.0", "0.2.0")),
          ]),
        )

      // Assert
      printed_text(printed)
      |> should
      |> be_equal(guide_project.output_file("fixing_older_release"))
      |> or_fail_with("The messages of old docs should be the guide's")
    }),
    it("a release notes file with another name", fn() {
      // Act
      let printed =
        lines("releases/notes-0.2.0.md", [#(1, MisnamedReleaseNotes)])

      // Assert
      printed_text(printed)
      |> should
      |> be_equal(guide_project.output_file("fixing_release_notes_name"))
      |> or_fail_with("The name message should be the guide's")
    }),
    it("errors that stop the check", fn() {
      // Act
      let printed = [
        config_error_line("name = my_app\n"),
        config_error_line("name = \"my_app\"\nname = \"app\"\n"),
        config_error_line("name = \"my_app\"\n"),
        config_error_line("version = \"0.2.0\"\n"),
        config_error_line("name = \"my_app\"\nversion = \"0.2.0\"\n"),
        config_error_line(
          "name = \"my_app\"\nversion = \"0.2.0\"\nrepository = { type = \"gitlab\", user = \"me\", repo = \"my_app\" }\n",
        ),
        config_error_line(
          gleam_toml <> "\n[tools.dream_snippets]\nmarkdown = \"docs\"\n",
        ),
        config_error_line(
          gleam_toml <> "\n[tools.dream_snippets]\nmarkdown = [\"docs\", 1]\n",
        ),
        config_error_line(
          gleam_toml <> "\n[tools.dream_snippets]\nguide = [\"docs\"]\n",
        ),
        config_error_line(
          gleam_toml
          <> "\n[tools.dream_snippets]\nchecked_from_version = \"1.0\"\n",
        ),
        "error: " <> dream_snippets.describe_error(MissingRoot("examples")),
        "error: "
          <> dream_snippets.describe_error(ReadFailed(
          "gleam.toml",
          simplifile.Enoent,
        )),
        "error: "
          <> dream_snippets.describe_error(ListFailed("docs", simplifile.Eacces)),
      ]

      // Assert
      printed_text(printed)
      |> should
      |> be_equal(guide_project.output_file("fixing_errors"))
      |> or_fail_with("The error lines should be the guide's")
    }),
  ])
}
