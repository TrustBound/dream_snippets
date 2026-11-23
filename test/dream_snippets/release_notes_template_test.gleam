//// Tests for the release notes template check in `dream_snippets/check`,
//// which fails when release notes do not follow the template.
////
//// Each fixture is a small inline file, so the tests never read real
//// release notes. The guide tests read the real "Release notes template"
//// guide, so that its list of sections cannot drift from the code.

import dream_snippets/check.{
  type TemplateSection, ConflictingReleaseNotesSections, MissingReleaseDate,
  MissingReleaseNotesChoice, MissingReleaseNotesSection,
  MissingReleaseNotesSubsection, OptionalSection, Problem,
  ReleaseNotesSectionOutOfOrder, ReleaseNotesTitleMismatch,
  RepeatedReleaseNotesSection, RequiredSection, UnknownReleaseNotesSection,
}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{type UnitNode, describe, group, it}
import fixtures/check_context.{project}
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import simplifile

const file = "releases/release-3.0.0.md"

const guide_path = "docs/guides/release-notes-template.md"

const no_difference = "the guide lists the sections of the template"

pub fn tests() -> TestSuite {
  describe("dream_snippets/check release notes template", [
    passing_tests(),
    title_tests(),
    section_tests(),
    describe_tests(),
    guide_tests(),
  ])
}

/// Joins lines into the text of a file.
fn notes(lines: List(String)) -> String {
  string.join(lines, "\n") <> "\n"
}

/// The lines of release notes that follow the template, with
/// `## Upgrading` and its `### Migration Guide`.
fn upgrade_lines() -> List(String) {
  [
    "# my_app 3.0.0 Release Notes",
    "",
    "**Release Date:** 2026-11-20",
    "",
    "## Key Highlights",
    "## What's New",
    "## Testing",
    "## Upgrading",
    "### Migration Guide",
    "## Documentation",
    "## Community",
  ]
}

/// Replaces the line at a 1-based line number.
fn replace_line(
  lines: List(String),
  number: Int,
  text: String,
) -> List(String) {
  list.index_map(lines, fn(line, index) {
    case index + 1 == number {
      True -> text
      False -> line
    }
  })
}

/// Removes the line at a 1-based line number.
fn remove_line(lines: List(String), number: Int) -> List(String) {
  lines
  |> list.index_map(fn(line, index) { #(index + 1, line) })
  |> list.filter(fn(entry) { entry.0 != number })
  |> list.map(fn(entry) { entry.1 })
}

fn passing_tests() -> UnitNode {
  group("release notes that follow the template", [
    it("passes release notes with Upgrading and a Migration Guide", fn() {
      // Arrange
      let text = notes(upgrade_lines())

      // Act
      let problems = check.check_release_notes_template(file, text)

      // Assert
      problems
      |> should
      |> be_equal([])
      |> or_fail_with("Release notes that follow the template should pass")
    }),
    it("passes a first release with every optional section and badges", fn() {
      // Arrange
      let text =
        notes([
          "# Dream Test 3.0.0 Release Notes",
          "Intro text.",
          "**Release Date:** not released yet (draft)",
          "## Key Highlights",
          "## What's New <a href=\"x\"><img alt=\"Tested snippet\"></a>",
          "## Deprecated",
          "## Removed",
          "## Bug Fixes",
          "## Known Limits",
          "## Testing",
          "## Installing",
          "## Acknowledgements",
          "## Documentation",
          "## Community",
        ])

      // Act
      let problems = check.check_release_notes_template(file, text)

      // Assert
      problems
      |> should
      |> be_equal([])
      |> or_fail_with("Each section of the template should be allowed")
    }),
    it("ignores headings in code fences", fn() {
      // Arrange
      let text =
        notes(
          list.append(upgrade_lines(), [
            "```markdown", "## Files changed", "## Testing", "```", "~~~",
            "## Removed",
          ]),
        )

      // Act
      let problems = check.check_release_notes_template(file, text)

      // Assert
      problems
      |> should
      |> be_equal([])
      |> or_fail_with("A heading in a fence should not count")
    }),
    it("reads the title version of a pre-release from the file name", fn() {
      // Arrange
      let text =
        notes(replace_line(
          upgrade_lines(),
          1,
          "# my_app 3.0.0-rc.1 Release Notes",
        ))

      // Act
      let problems =
        check.check_release_notes_template(
          "releases/release-3.0.0-rc.1.md",
          text,
        )

      // Assert
      problems
      |> should
      |> be_equal([])
      |> or_fail_with("The title should use the version as the name writes it")
    }),
  ])
}

fn title_tests() -> UnitNode {
  group("the title and the release date", [
    it("fails a title with another version than the file name", fn() {
      // Arrange
      let text =
        notes(replace_line(upgrade_lines(), 1, "# my_app 2.0.0 Release Notes"))

      // Act
      let problems = check.check_release_notes_template(file, text)

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(
          file,
          1,
          ReleaseNotesTitleMismatch("# my_app 2.0.0 Release Notes", "3.0.0"),
        ),
      ])
      |> or_fail_with("The title should use the version of the file name")
    }),
    it("fails a title with no name", fn() {
      // Arrange
      let text =
        notes(replace_line(upgrade_lines(), 1, "#  3.0.0 Release Notes"))

      // Act
      let problems = check.check_release_notes_template(file, text)

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(
          file,
          1,
          ReleaseNotesTitleMismatch("#  3.0.0 Release Notes", "3.0.0"),
        ),
      ])
      |> or_fail_with("The title should name the project")
    }),
    it("fails the title of a file name with no version", fn() {
      // Arrange
      let text = notes(upgrade_lines())

      // Act
      let problems =
        check.check_release_notes_template("releases/notes.md", text)

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(
          "releases/notes.md",
          1,
          ReleaseNotesTitleMismatch("# my_app 3.0.0 Release Notes", "<version>"),
        ),
      ])
      |> or_fail_with("A title cannot match a name with no version")
    }),
    it("fails release notes with no release date line", fn() {
      // Arrange
      let text = notes(remove_line(upgrade_lines(), 3))

      // Act
      let problems = check.check_release_notes_template(file, text)

      // Assert
      problems
      |> should
      |> be_equal([Problem(file, 1, MissingReleaseDate)])
      |> or_fail_with("The release date line should be required")
    }),
    it("fails a release date line after the first section", fn() {
      // Arrange
      let text =
        notes(
          upgrade_lines()
          |> remove_line(3)
          |> list.append(["**Release Date:** 2026-11-20"]),
        )

      // Act
      let problems = check.check_release_notes_template(file, text)

      // Assert
      problems
      |> should
      |> be_equal([Problem(file, 1, MissingReleaseDate)])
      |> or_fail_with("The release date should come before the first section")
    }),
    it("fails an empty file for each missing part", fn() {
      // Act
      let problems = check.check_release_notes_template(file, "")

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(file, 1, ReleaseNotesTitleMismatch("", "3.0.0")),
        Problem(file, 1, MissingReleaseDate),
        Problem(file, 1, MissingReleaseNotesSection("Key Highlights")),
        Problem(file, 1, MissingReleaseNotesSection("What's New")),
        Problem(file, 1, MissingReleaseNotesSection("Testing")),
        Problem(file, 1, MissingReleaseNotesChoice(["Upgrading", "Installing"])),
        Problem(file, 1, MissingReleaseNotesSection("Documentation")),
        Problem(file, 1, MissingReleaseNotesSection("Community")),
      ])
      |> or_fail_with("Each missing part should be a problem at line 1")
    }),
  ])
}

fn section_tests() -> UnitNode {
  group("the sections", [
    it("fails a section that is not in the template", fn() {
      // Arrange
      let text = notes(replace_line(upgrade_lines(), 4, "## Files changed"))

      // Act
      let problems = check.check_release_notes_template(file, text)

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(file, 4, UnknownReleaseNotesSection("Files changed")),
      ])
      |> or_fail_with("An unknown section should be named")
    }),
    it("fails a section that comes after a later one of the template", fn() {
      // Arrange
      let text =
        notes([
          "# my_app 3.0.0 Release Notes",
          "**Release Date:** 2026-11-20",
          "## Key Highlights",
          "## What's New",
          "## Upgrading",
          "### Migration Guide",
          "## Testing",
          "## Documentation",
          "## Community",
        ])

      // Act
      let problems = check.check_release_notes_template(file, text)

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(
          file,
          7,
          ReleaseNotesSectionOutOfOrder(section: "Testing", after: "Upgrading"),
        ),
      ])
      |> or_fail_with("Testing should come before Upgrading")
    }),
    it("fails a section that is in the file two times", fn() {
      // Arrange
      let text =
        notes([
          "# my_app 3.0.0 Release Notes",
          "**Release Date:** 2026-11-20",
          "## Key Highlights",
          "## What's New",
          "## Bug Fixes",
          "## Bug Fixes",
          "## Testing",
          "## Installing",
          "## Documentation",
          "## Community",
        ])

      // Act
      let problems = check.check_release_notes_template(file, text)

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(
          file,
          6,
          RepeatedReleaseNotesSection(section: "Bug Fixes", first_line: 5),
        ),
      ])
      |> or_fail_with("The second Bug Fixes should be named with the first")
    }),
    it("fails release notes with both Upgrading and Installing", fn() {
      // Arrange
      let text = notes(replace_line(upgrade_lines(), 9, "## Installing"))

      // Act
      let problems = check.check_release_notes_template(file, text)

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(
          file,
          8,
          MissingReleaseNotesSubsection(
            section: "Upgrading",
            subsection: "Migration Guide",
          ),
        ),
        Problem(
          file,
          9,
          ConflictingReleaseNotesSections(
            section: "Installing",
            other: "Upgrading",
          ),
        ),
      ])
      |> or_fail_with("Only one of Upgrading and Installing should be allowed")
    }),
    it("fails release notes with no Testing section", fn() {
      // Arrange
      let text = notes(remove_line(upgrade_lines(), 7))

      // Act
      let problems = check.check_release_notes_template(file, text)

      // Assert
      problems
      |> should
      |> be_equal([Problem(file, 1, MissingReleaseNotesSection("Testing"))])
      |> or_fail_with("Testing should be required")
    }),
    it("fails release notes with neither Upgrading nor Installing", fn() {
      // Arrange
      let text = notes(upgrade_lines() |> remove_line(9) |> remove_line(8))

      // Act
      let problems = check.check_release_notes_template(file, text)

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(file, 1, MissingReleaseNotesChoice(["Upgrading", "Installing"])),
      ])
      |> or_fail_with("One of Upgrading and Installing should be required")
    }),
    it("fails an Upgrading section with no Migration Guide in it", fn() {
      // Arrange
      let text =
        notes(
          upgrade_lines()
          |> remove_line(9)
          |> list.append(["### Migration Guide"]),
        )

      // Act
      let problems = check.check_release_notes_template(file, text)

      // Assert
      problems
      |> should
      |> be_equal([
        Problem(
          file,
          8,
          MissingReleaseNotesSubsection(
            section: "Upgrading",
            subsection: "Migration Guide",
          ),
        ),
      ])
      |> or_fail_with("The Migration Guide should be inside Upgrading")
    }),
  ])
}

fn describe_tests() -> UnitNode {
  group("describe_reason", [
    it("describes every reason of the release notes template", fn() {
      // Arrange
      let reasons = [
        ReleaseNotesTitleMismatch("# my_app 2.0.0 Release Notes", "3.0.0"),
        MissingReleaseDate,
        UnknownReleaseNotesSection("Files changed"),
        ReleaseNotesSectionOutOfOrder(section: "Testing", after: "Upgrading"),
        RepeatedReleaseNotesSection(section: "Bug Fixes", first_line: 12),
        ConflictingReleaseNotesSections(
          section: "Installing",
          other: "Upgrading",
        ),
        MissingReleaseNotesSection("Testing"),
        MissingReleaseNotesChoice(["Upgrading", "Installing"]),
        MissingReleaseNotesSubsection(
          section: "Upgrading",
          subsection: "Migration Guide",
        ),
      ]

      // Act
      let descriptions = list.map(reasons, check.describe_reason(_, project()))

      // Assert
      descriptions
      |> should
      |> be_equal([
        "the first line is \"# my_app 2.0.0 Release Notes\", but the template wants the title \"# <Name> 3.0.0 Release Notes\"; see \"Release notes template\" in docs/contributing/release-notes.md",
        "there is no line that starts with \"**Release Date:**\" between the title and the first section, but the template wants one there; see \"Release notes template\" in docs/contributing/release-notes.md",
        "\"## Files changed\" is not a section of the release notes template; see \"Release notes template\" in docs/contributing/release-notes.md",
        "\"## Testing\" comes after \"## Upgrading\", but the template has it before \"## Upgrading\"; see \"Release notes template\" in docs/contributing/release-notes.md",
        "\"## Bug Fixes\" is in the file again (first at line 12), but the template has each section one time at most; see \"Release notes template\" in docs/contributing/release-notes.md",
        "\"## Upgrading\" and \"## Installing\" are both in the file, but the template allows only one of them; see \"Release notes template\" in docs/contributing/release-notes.md",
        "the section \"## Testing\" is missing, but the template requires it; see \"Release notes template\" in docs/contributing/release-notes.md",
        "neither \"## Upgrading\" nor \"## Installing\" is in the file, but the template requires one of them; see \"Release notes template\" in docs/contributing/release-notes.md",
        "\"## Upgrading\" has no \"### Migration Guide\", but the template requires it in that section; see \"Release notes template\" in docs/contributing/release-notes.md",
      ])
      |> or_fail_with("Each message should name the problem and the guide")
    }),
  ])
}

// ---------------------------------------------------------------------------
// The guide
// ---------------------------------------------------------------------------

/// One item of a section list: the headings in backticks, joined with
/// ` or `, and the mark `required` or `optional`.
type SectionItem {
  SectionItem(headings: String, mark: String)
}

/// The section list of the template in the code, as items.
fn template_items() -> List(SectionItem) {
  list.map(check.release_notes_template, template_item)
}

fn template_item(section: TemplateSection) -> SectionItem {
  let headings =
    section.choices
    |> list.map(fn(choice) { "`" <> choice.name <> "`" })
    |> string.join(" or ")
  let mark = case section.presence {
    RequiredSection -> "required"
    OptionalSection -> "optional"
  }
  SectionItem(headings:, mark:)
}

/// Reads the section list of the guide. The list is the numbered items
/// after the `## The sections` heading and before the next `##` heading.
/// Each item has this form, and other lines are skipped:
///
/// ```text
/// <number>. `<heading>`: <mark>
/// <number>. `<heading>` or `<heading>`: <mark>, <more text>
/// ```
///
/// `<mark>` is `required` or `optional`. The text after the first `, ` is
/// for the reader and is not compared.
fn guide_items(guide: String) -> List(SectionItem) {
  guide
  |> string.split("\n")
  |> list.drop_while(fn(line) { line != "## The sections" })
  |> list.drop(1)
  |> list.take_while(fn(line) { !string.starts_with(line, "## ") })
  |> list.filter_map(numbered_item_text)
  |> list.map(guide_item)
}

fn numbered_item_text(line: String) -> Result(String, Nil) {
  use #(number, item) <- result.try(string.split_once(line, ". "))
  use _number <- result.map(int.parse(number))
  item
}

fn guide_item(item: String) -> SectionItem {
  let #(headings, rest) =
    string.split_once(item, ": ") |> result.unwrap(#(item, ""))
  let #(mark, _more) =
    string.split_once(rest, ", ") |> result.unwrap(#(rest, ""))
  SectionItem(headings:, mark:)
}

/// Describes the first difference between the list of the guide and the
/// list of the code, or returns `no_difference`. `number` is the item
/// number of the first items.
fn first_difference(
  guide: List(SectionItem),
  code: List(SectionItem),
  number: Int,
) -> String {
  case guide, code {
    [], [] -> no_difference
    [guide_first, ..guide_rest], [code_first, ..code_rest]
      if guide_first == code_first
    -> first_difference(guide_rest, code_rest, number + 1)
    [guide_first, ..], [code_first, ..] ->
      item_label(number)
      <> "the guide has "
      <> describe_item(guide_first)
      <> ", but the code has "
      <> describe_item(code_first)
    [guide_first, ..], [] ->
      item_label(number)
      <> "the guide has "
      <> describe_item(guide_first)
      <> ", but the code has no more sections"
    [], [code_first, ..] ->
      item_label(number)
      <> "the guide has no more items, but the code has "
      <> describe_item(code_first)
  }
}

fn item_label(number: Int) -> String {
  "item " <> int.to_string(number) <> ": "
}

fn describe_item(item: SectionItem) -> String {
  "\"" <> item.headings <> ": " <> item.mark <> "\""
}

fn guide_tests() -> UnitNode {
  group("the Release notes template guide", [
    it("lists the sections of the template in the code", fn() {
      // Arrange
      let guide = simplifile.read(guide_path)

      // Act
      let difference =
        result.map(guide, fn(text) {
          first_difference(guide_items(text), template_items(), 1)
        })

      // Assert
      difference
      |> should
      |> be_equal(Ok(no_difference))
      |> or_fail_with(
        "The section list of the guide should be the template in the code",
      )
    }),
    it("names the first item that differs from the code", fn() {
      // Arrange
      let guide =
        notes([
          "## The sections",
          "",
          "1. `Key Highlights`: required",
          "2. `What's New`: optional",
          "3. `Removed`: optional",
          "",
          "## Next",
          "",
          "4. `Testing`: required",
        ])

      // Act
      let difference = first_difference(guide_items(guide), template_items(), 1)

      // Assert
      difference
      |> should
      |> be_equal(
        "item 2: the guide has \"`What's New`: optional\", but the code has \"`What's New`: required\"",
      )
      |> or_fail_with("The message should name the first difference")
    }),
    it("names a code section that the guide leaves out", fn() {
      // Arrange
      let guide =
        notes(["## The sections", "", "1. `Key Highlights`: required"])

      // Act
      let difference = first_difference(guide_items(guide), template_items(), 1)

      // Assert
      difference
      |> should
      |> be_equal(
        "item 2: the guide has no more items, but the code has \"`What's New`: required\"",
      )
      |> or_fail_with("The message should name the missing section")
    }),
    it("names a guide item that the code does not have", fn() {
      // Arrange
      let items = list.append(template_items(), [SectionItem("`Extra`", "")])

      // Act
      let difference = first_difference(items, template_items(), 1)

      // Assert
      difference
      |> should
      |> be_equal(
        "item 12: the guide has \"`Extra`: \", but the code has no more sections",
      )
      |> or_fail_with("The message should name the extra item")
    }),
  ])
}
