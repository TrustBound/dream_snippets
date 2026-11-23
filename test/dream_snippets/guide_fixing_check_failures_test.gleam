//// Tests for the "Fix a failed check" guide
//// (docs/guides/fixing-check-failures.md). Each test describes the
//// problems or errors that the guide shows, with the functions that the
//// command uses, for the example project `my_app` 0.2.0 with no settings,
//// and asserts the exact lines that the guide shows.

import dream_snippets.{InvalidConfig, ListFailed, MissingRoot, ReadFailed}
import dream_snippets/check.{
  type Project, type Reason, BlockDiffers, DiffLineNotFound, EmptyDiffBlock,
  ExampleNotInGuide, FilesAtTag, ForeignGuideLink, ForeignLink, GitUnavailable,
  GuideAnchorNotFound, GuideBadgeNotAllowed, HiddenGleamCode, HunkHeaderNotFound,
  LineRangePastEnd, MalformedBadge, MalformedDiffBadge, MalformedGuideBadge,
  MalformedLineRange, MalformedOldCodeBadge, MisnamedReleaseNotes,
  MissingBadgeHeading, MissingDiffBadgeHeading, MissingDiffFileHeader,
  MissingFile, MissingFileAtTag, MissingGuideAnchor, MissingGuideBadge,
  MissingGuideFile, MissingOldTag, MissingReleaseTag, NoDiffForPath,
  NotAGuidePath, NotAnOlderRelease, NotCompareLink, OldCodeBadgeWithOtherBadge,
  OldCodeDiffers, OldCodeNotAllowed, OldTestedSourceLine, Problem,
  ReleaseNotBeforeVersion, ReversedLineRange, UnclosedFence, UnreadableFile,
  UnsafeOldCodeLink, WorkingTree, WrongDiffAnchor, WrongGuideTag, WrongNewTag,
  WrongTag,
}
import dream_snippets/config
import dream_snippets/git.{GitFailed, GitNotFound}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import gleam/list
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
      printed
      |> should
      |> be_equal([
        "docs/guides/getting-started.md:5: this gleam code block has no heading with the tested snippet badge directly above it (one blank line between is allowed)",
        "docs/guides/getting-started.md:5: the tested snippet badge is not in the exact format; copy it from https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html",
        "docs/guides/getting-started.md:3: the old \"🧪 Tested source\" line is not used now; put the tested snippet badge at the end of the heading above the code block",
      ])
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
      printed
      |> should
      |> be_equal([
        "docs/guides/getting-started.md:5: the badge link https://github.com/someone/my_app/blob/0.2.0/test/snippets/guide_getting_started_greeting.gleam does not point at a file in https://github.com/me/my_app",
        "docs/guides/getting-started.md:5: the badge link uses the tag 0.1.0, but this file must link at the tag 0.2.0 (the docs of my_app use the version in gleam.toml)",
        "docs/guides/getting-started.md:5: the badge links to test/snippets/greeting.gleam, which is not a file in this repository",
        "docs/guides/getting-started.md:5: cannot read test/snippets/guide_getting_started_greeting.gleam: Permission denied",
      ])
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
      printed
      |> should
      |> be_equal([
        "docs/guides/getting-started.md:5: the line anchor #L5:L9 is not #L<n> or #L<start>-L<end>",
        "docs/guides/getting-started.md:5: the line range starts at line 9, after its end at line 5",
        "docs/guides/getting-started.md:5: the line range ends at line 20, but the file has 16 lines",
      ])
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
      printed
      |> should
      |> be_equal([
        "docs/guides/getting-started.md:5: the code block is not the same as test/snippets/guide_getting_started_greeting.gleam; the first difference is at line 9",
        "docs/guides/getting-started.md:14: the code block is not the same as test/snippets/guide_getting_started_greeting.gleam#L13-L16; the first difference is at line 15",
      ])
      |> or_fail_with("The code messages should be the guide's")
    }),
    it("the fences", fn() {
      // Act
      let printed =
        lines("docs/guides/usage.md", [
          #(4, HiddenGleamCode("text")),
          #(9, HiddenGleamCode("")),
          #(12, UnclosedFence),
        ])

      // Assert
      printed
      |> should
      |> be_equal([
        "docs/guides/usage.md:4: this line looks like Gleam code in a text code fence; put Gleam code in a gleam block with the tested snippet badge",
        "docs/guides/usage.md:9: this line looks like Gleam code in a code fence with no language; put Gleam code in a gleam block with the tested snippet badge",
        "docs/guides/usage.md:12: this code fence has no closing fence",
      ])
      |> or_fail_with("The fence messages should be the guide's")
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
      printed
      |> should
      |> be_equal([
        "README.md:5: this README example heading has no guide badge after its tested snippet badge; copy the heading from https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html",
        "README.md:5: the guide badge is not in the exact format, or it is not directly after the tested snippet badge; copy the heading from https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html",
        "README.md:5: the guide badge link https://hexdocs.pm/my_app/getting-started.html does not point at a file in https://github.com/me/my_app",
        "README.md:5: the guide badge link uses the tag 0.1.0, but this file must link at the tag 0.2.0 (the docs of my_app use the version in gleam.toml)",
        "README.md:5: the guide badge links to docs/usage.md, but it must link to a .md file under docs/guides",
        "README.md:5: the guide badge link to docs/guides/getting-started.md has no #<anchor>, but it must name the guide section of this example",
        "README.md:5: the guide badge links to docs/guides/greeting.md, which is not a file in this repository",
        "README.md:5: the guide badge links to the anchor #greet-a-user, but docs/guides/getting-started.md has no heading with that anchor",
        "README.md:5: docs/guides/getting-started.md has no tested snippet badge that links to test/snippets/guide_getting_started_greeting.gleam, but the guide of a README example must show that example",
        "docs/guides/getting-started.md:3: this heading has a guide badge, but only README example headings have one; here the heading has only the tested snippet badge",
      ])
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
      printed
      |> should
      |> be_equal([
        "docs/guides/upgrading.md:19: this diff block has no heading with the tested diff badge directly above it (one blank line between is allowed)",
        "docs/guides/upgrading.md:19: the tested diff badge is not in the exact format; copy it from https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html",
        "docs/guides/upgrading.md:19: the diff badge link https://github.com/me/my_app/compare/0.1.0..0.2.0 is not https://github.com/me/my_app/compare/<old tag>...<new tag>#diff-<digest>",
        "docs/guides/upgrading.md:19: the compare link ends at the tag 0.1.1, but this file must use the new tag 0.2.0 (the docs of my_app use the version in gleam.toml)",
        "docs/guides/upgrading.md:19: the diff block does not start with \"--- a/<path>\" and \"+++ b/<path>\" for one path of letters, digits and . _ - /",
        "docs/guides/upgrading.md:19: the diff block has no diff lines after its file header",
        "docs/guides/upgrading.md:19: the compare link anchor is not the one for src/my_app.gleam; use #diff-dc300fec45bded4a328557d8cdb35d83594380337bd562985800e8086dc62ebd",
        "docs/guides/upgrading.md:19: the tag 0.1.0 is not in this clone; fetch the tags with \"git fetch --tags\" (a shallow clone has none)",
        "docs/guides/upgrading.md:19: cannot run git: git is not on the PATH",
        "docs/guides/upgrading.md:19: cannot run git: git stopped with exit status 128",
        "docs/guides/upgrading.md:19: src/my_app.gleam has no changes since the tag 0.1.0",
        "docs/guides/upgrading.md:22: the hunk header @@ -1,4 +1,11 @@ is not a hunk header of the real diff, or it is out of order",
        "docs/guides/upgrading.md:24: this line is not in \"git diff 0.1.0 -- src/my_app.gleam\" at this place; a diff block shows lines of the real diff, in order and contiguous within a hunk",
      ])
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
      printed
      |> should
      |> be_equal([
        "docs/guides/upgrading.md:7: the code at an older release badge is not in the exact format, or the tag in its alt text or image is not the tag of its link; copy it from https://hexdocs.pm/dream_snippets/guides/tested-code-blocks.html",
        "docs/guides/upgrading.md:7: this heading has the code at an older release badge and another badge, but a heading with that badge has no other badge",
        "docs/guides/upgrading.md:7: the tag v0.1.0~1 or the path test/snippets/guide_upgrading_greet_lucy.gleam has characters that the check does not give to git (a tag has only letters, digits and . _ -, and a path also /)",
        "docs/guides/upgrading.md:7: the tag 0.2.0 is not a release before 0.2.0, the version in gleam.toml, so use the tested snippet badge for this code",
        "docs/guides/upgrading.md:7: the tag 0.1.0 is not in this clone; fetch the tags with \"git fetch --tags\" (a shallow clone has none)",
        "docs/guides/upgrading.md:7: the badge links to test/snippets/guide_upgrading_greet_lucy.gleam, which is not a file at the tag 0.1.0",
        "docs/guides/upgrading.md:7: the code block is not the same as test/snippets/guide_upgrading_greet_lucy.gleam#L4 at the tag 0.1.0; the first difference is at line 8",
        "README.md:5: the code at an older release badge is only allowed in the guides under docs/guides and in release notes, because the README, the changelog and doc comments show only code of the current version",
      ])
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
      printed
      |> should
      |> be_equal([
        "releases/release-0.1.0.md:11: the badge link uses the tag 0.2.0, but this file must link at the tag 0.1.0 (release notes and changelog sections link at the tag of their own release)",
        "releases/release-0.1.0.md:11: the code block is not the same as test/snippets/guide_getting_started_greeting.gleam at the tag 0.1.0; the first difference is at line 15",
        "releases/release-0.1.0.md:11: this block is in the docs of the release 0.1.0, so it is compared with the files at the tag 0.1.0, but that tag is not in this clone; fetch the tags with \"git fetch --tags\" (a shallow clone has none)",
        "releases/release-0.1.0.md:17: the tag 0.1.0 is not a release before 0.1.0, the release of these release notes, so use the tested snippet badge for this code",
        "releases/release-0.1.0.md:23: the compare link ends at the tag 0.2.0, but this file must use the new tag 0.1.0 (release notes and changelog sections link at the tag of their own release)",
        "releases/release-0.1.0.md:23: src/my_app.gleam has no changes between the tags 0.0.1 and 0.1.0",
        "releases/release-0.1.0.md:28: this line is not in \"git diff 0.0.1 0.1.0 -- src/my_app.gleam\" at this place; a diff block shows lines of the real diff, in order and contiguous within a hunk",
        "releases/release-0.3.0.md:11: this block is in the docs of the release 0.3.0, which is neither 0.2.0, the version in gleam.toml, nor a release before it; set the version in gleam.toml to the release that these docs are for",
      ])
      |> or_fail_with("The messages of old docs should be the guide's")
    }),
    it("a release notes file with another name", fn() {
      // Act
      let printed =
        lines("releases/notes-0.2.0.md", [#(1, MisnamedReleaseNotes)])

      // Assert
      printed
      |> should
      |> be_equal([
        "releases/notes-0.2.0.md:1: a release notes file must be named \"release-<version>.md\", for example \"release-1.2.0.md\"; see \"Release notes template\" in https://hexdocs.pm/dream_snippets/guides/release-notes-template.html",
      ])
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
      printed
      |> should
      |> be_equal([
        "error: gleam.toml is not valid TOML: found m where value was expected",
        "error: gleam.toml sets the key name twice",
        "error: gleam.toml has no version = \"...\" line before its first [section]",
        "error: gleam.toml has no name = \"...\" line before its first [section]",
        "error: gleam.toml has no repository = { type = \"github\", user = \"...\", repo = \"...\" }",
        "error: gleam.toml names a gitlab repository; the badges link at GitHub, so the repository type must be github",
        "error: tools.dream_snippets.markdown in gleam.toml must be an array of strings, but its TOML type is String",
        "error: tools.dream_snippets.markdown in gleam.toml must be an array of strings",
        "error: tools.dream_snippets.guide in gleam.toml is not a setting; the settings are markdown, changelog, release_notes, gleam_source, checked_from_version, guides, badge_guide, release_notes_guide",
        "error: tools.dream_snippets.checked_from_version in gleam.toml is \"1.0\", which is not a major.minor.patch version",
        "error: examples is set in [tools.dream_snippets] in gleam.toml, but it does not exist",
        "error: Cannot read gleam.toml: No such file or directory",
        "error: Cannot list docs: Permission denied",
      ])
      |> or_fail_with("The error lines should be the guide's")
    }),
  ])
}
