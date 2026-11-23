//// The checks: each code block in a document is backed by tested code.
////
//// Each ```` ```gleam ```` block in a Markdown doc, and each one in a `///`
//// or `////` doc comment in `src/`, has a heading directly above it that
//// ends with the "tested snippet" badge. The badge links to a file in the
//// GitHub repository of the project, at the tag of the version in
//// `gleam.toml`, for example
//// `https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/name.gleam#L8-L10`.
//// The block is that whole file, or exactly that line range, byte for byte.
//// The tests of the project compile and run the file, so the code in the
//// docs is code that works.
////
//// A fence with another language (or no language) must not hold Gleam
//// code, because then the check would not see it. A line in such a fence
//// is Gleam code when it is one of these forms, which no other common
//// language of the docs has (see `looks_like_gleam`):
////
//// - `import a/b` (a module path with a `/`) or `import a.{...}`
//// - `fn name(` or `pub fn name(`
//// - `pub type Name`, `pub opaque type Name` or `type Name` with no `=`
//// - `use x <- ...`
//// - `let assert ...`
//// - a pipe into a module function, such as `|> list.map(`
////
//// A ```` ```markdown ```` fence holds an example document. Its fences are
//// checked like the fences of any other document, and its other lines must
//// not look like Gleam code.
////
//// A ```` ```diff ```` block shows how code changed between two releases,
//// for example in an upgrade guide. Old code does not compile on the new
//// version, so it cannot be a tested snippet. It is an excerpt of the real
//// git diff instead. Its heading ends with the "tested diff" badge, which
//// links to GitHub's compare view of one file, for example
//// `https://github.com/TrustBound/dream/compare/2.4.1...3.0.0#diff-<digest>`,
//// where `<digest>` is the SHA-256 hex digest of the file's path (GitHub's
//// own anchor for the file). The block starts with the `--- a/<path>` and
//// `+++ b/<path>` lines, then holds lines of the diff, with or without
//// `@@` hunk headers. The check runs `git diff <old tag> -- <path>` against
//// the working tree, and each run of lines must be in that diff, in order
//// and contiguous within one hunk. The new tag is the version in
//// `gleam.toml`, because that tag does not exist before the release.
////
//// In the root README, the heading of each ```` ```gleam ```` block also
//// has the guide badge after the tested snippet badge. It links to the
//// section of a guide that shows the example (see `check_readme`). In
//// every other document, a heading has no guide badge.
////
//// Release notes and changelog entries are checked from the
//// `checked_from_version` of the `CheckContext` on. Older ones show code
//// that was right for their own version, so they are not.
////
//// The functions here are pure. They get files and git through a
//// `CheckContext`, so tests can give them fake files and a fake git
//// history. `dream_snippets.check_project` lists and reads the files of a
//// real project and gives the real git to the context.

import dream_snippets/git.{type GitError}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{type Order}
import gleam/result
import gleam/string
import gleam/uri
import simplifile

// ---------------------------------------------------------------------------
// Scope
// ---------------------------------------------------------------------------

/// The kind of file that a checked root holds.
pub type DocumentKind {
  /// A Markdown document (`.md`). Each fenced code block in it is checked.
  MarkdownDocument
  /// A Gleam source file (`.gleam`). Each fenced code block in its `///`
  /// and `////` doc comments is checked.
  GleamSource
  /// A release notes file, `release-<version>.md`. It is checked like a
  /// Markdown document when its version is `checked_from_version` or later,
  /// and skipped when it is older or has no version in its name.
  ReleaseNotes
  /// The changelog. Its `## [<version>]` sections for `checked_from_version`
  /// and later, its `## [Unreleased]` section and the text before the first
  /// section are checked. The sections of older versions are skipped.
  Changelog
}

/// A release version, `major.minor.patch`.
pub type Version {
  Version(major: Int, minor: Int, patch: Int)
}

/// The project whose docs are checked, as its `gleam.toml` describes it.
///
/// `name` is the package name, used in the message of a wrong tag. `version`
/// is the release tag that every badge link must use. `repository` is the
/// GitHub repository that every badge must link at. `badge_guide` is the
/// document or address that a malformed badge message tells the reader to
/// copy the badge from. `release_notes_guide` is the document or address
/// that a release notes template message tells the reader to read.
/// `guides` are the directories that hold the guides of the project, such
/// as `docs/guides`: the guide badge of a README example must link to a
/// `.md` file under one of them.
pub type Project {
  Project(
    name: String,
    version: String,
    repository: GitHubRepository,
    badge_guide: String,
    release_notes_guide: String,
    guides: List(String),
  )
}

/// A GitHub repository, from the `repository` field of `gleam.toml`:
/// `owner` is its `user` and `name` its `repo`.
pub type GitHubRepository {
  GitHubRepository(owner: String, name: String)
}

// ---------------------------------------------------------------------------
// The badge
// ---------------------------------------------------------------------------

/// The text between the start of a badge and its link address.
const badge_start = " <a href=\""

/// The exact text after the link address of a badge, to the end of the
/// heading.
const badge_end =
  "\"><img align=\"right\" alt=\"Tested snippet\" src=\"https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square\"></a>"

/// The exact text after the link address of a diff badge, to the end of the
/// heading.
const diff_badge_end =
  "\"><img align=\"right\" alt=\"Tested diff\" src=\"https://img.shields.io/badge/%F0%9F%A7%AA_tested-diff-lightgreen.svg?style=flat-square\"></a>"

/// The alt text of the guide badge image. The guide badge form is in
/// `guide_badge_alt`, `guide_badge_image` and `guide_badge_end` only.
const guide_badge_alt = "Guide"

/// The image address of the guide badge.
const guide_badge_image =
  "https://img.shields.io/badge/%F0%9F%93%96_read-guide-blue.svg?style=flat-square"

/// The exact text after the link address of a guide badge, to the end of
/// the heading. The guide badge comes after the tested snippet badge.
const guide_badge_end =
  "\"><img align=\"right\" alt=\""
  <> guide_badge_alt
  <> "\" src=\""
  <> guide_badge_image
  <> "\"></a>"

/// The text that shows that a heading has a guide badge, in any form.
const guide_badge_marker = " alt=\"" <> guide_badge_alt <> "\""

/// The start of the anchor that names one file in a compare view. The
/// SHA-256 hex digest of the file's path follows it.
const diff_anchor_prefix = "diff-"

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/// One line of a document, with its 1-based line number in the file.
pub type Line {
  Line(number: Int, text: String)
}

/// What the checks need from the outside.
///
/// `project` names the repository that badge links must point at and the
/// release tag that they must use. `checked_from_version` is the first
/// version whose release notes and changelog section are checked.
/// `read_source` reads a file by its path relative to the repository root.
/// `tag_exists` tells whether a git tag is in the local clone.
/// `diff_from_tag` returns the text of the git diff of one path (the second
/// argument) from a tag (the first argument) to the working tree.
/// `dream_snippets.check_project` gives them `simplifile.read`,
/// `git.tag_exists` and `git.diff_from_tag`. Tests can give them lookups in
/// lists, so that they do not depend on real files or a real history.
pub type CheckContext {
  CheckContext(
    project: Project,
    checked_from_version: Version,
    read_source: fn(String) -> Result(String, simplifile.FileError),
    tag_exists: fn(String) -> Result(Bool, GitError),
    diff_from_tag: fn(String, String) -> Result(String, GitError),
  )
}

/// Why a code block fails the check.
pub type Reason {
  /// A Gleam block has no heading with the badge directly above it.
  MissingBadgeHeading
  /// A Gleam block uses the old `🧪 Tested source` line next to it.
  OldTestedSourceLine
  /// The heading has a badge, but not in the exact format.
  MalformedBadge
  /// The badge links to another repository or host, or out of the
  /// repository.
  ForeignLink(url: String)
  /// The tag in the badge link is not the release tag of the document (see
  /// `CheckContext`).
  WrongTag(found: String, expected: String)
  /// The linked file does not exist in this repository.
  MissingFile(path: String)
  /// The linked file exists but cannot be read.
  UnreadableFile(path: String, reason: simplifile.FileError)
  /// The line anchor is not `#L<n>` or `#L<start>-L<end>`.
  MalformedLineRange(anchor: String)
  /// The line range starts after it ends.
  ReversedLineRange(start: Int, end: Int)
  /// The line range ends after the last line of the file.
  LineRangePastEnd(end: Int, line_count: Int)
  /// The block is not the same as the linked file or range.
  /// `first_difference_line` is the line in the document where the first
  /// difference is.
  BlockDiffers(path: String, anchor: String, first_difference_line: Int)
  /// A fence with another language holds a line that looks like Gleam.
  /// `language` is the fence language, or an empty string for none.
  HiddenGleamCode(language: String)
  /// A fence has no closing fence.
  UnclosedFence
  /// A diff block has no heading with the diff badge directly above it.
  MissingDiffBadgeHeading
  /// The heading has a diff badge, but not in the exact format.
  MalformedDiffBadge
  /// The diff badge does not link to a compare view of this repository, as
  /// `<old tag>...<new tag>#diff-<digest>`, or a tag has characters that a
  /// tag name in this repository does not have.
  NotCompareLink(url: String)
  /// The new tag in the compare link is not the release tag of the document
  /// (see `CheckContext`).
  WrongNewTag(found: String, expected: String)
  /// The diff block does not start with `--- a/<path>` and `+++ b/<path>`
  /// for one path, or the path has characters that are not allowed.
  MissingDiffFileHeader
  /// The diff block has no lines after its file header.
  EmptyDiffBlock
  /// The anchor in the compare link is not the digest of the path in the
  /// block. `expected` is the right anchor, with its `#`.
  WrongDiffAnchor(path: String, expected: String)
  /// The old tag in the compare link is not in the local clone.
  MissingOldTag(tag: String)
  /// git could not be run, or it failed.
  GitUnavailable(error: GitError)
  /// The file did not change between the old tag and now.
  NoDiffForPath(path: String, old_tag: String)
  /// A hunk header in the block is not a hunk header of the real diff, or
  /// it is out of order.
  HunkHeaderNotFound(header: String)
  /// A line of the block is not in the real diff at that place.
  DiffLineNotFound(path: String, old_tag: String)
  /// The first line of release notes is not `# <Name> <version> Release
  /// Notes`. `found` is the first line, and `version` is the version in the
  /// file name (or `<version>` when the name has none).
  ReleaseNotesTitleMismatch(found: String, version: String)
  /// Release notes have no line that starts with `**Release Date:**`
  /// between the title and the first `##` section.
  MissingReleaseDate
  /// A `##` section of release notes is not a section of the template.
  UnknownReleaseNotesSection(section: String)
  /// A `##` section of release notes comes after `after`, but the template
  /// has it before `after`.
  ReleaseNotesSectionOutOfOrder(section: String, after: String)
  /// A `##` section of release notes is in the file again. `first_line` is
  /// the line where it is first.
  RepeatedReleaseNotesSection(section: String, first_line: Int)
  /// Release notes have two `##` sections that the template has as a
  /// choice of one, such as `Upgrading` and `Installing`. `other` is the
  /// one that comes first.
  ConflictingReleaseNotesSections(section: String, other: String)
  /// Release notes do not have a `##` section that the template requires.
  MissingReleaseNotesSection(section: String)
  /// Release notes have none of the `##` sections of a required choice,
  /// such as `Upgrading` or `Installing`.
  MissingReleaseNotesChoice(sections: List(String))
  /// A `##` section of release notes does not have a `###` heading that
  /// the template requires in it.
  MissingReleaseNotesSubsection(section: String, subsection: String)
  /// An example heading in the README has no guide badge after its tested
  /// snippet badge.
  MissingGuideBadge
  /// An example heading in the README has a guide badge, but not in the
  /// exact form, or not directly after the tested snippet badge.
  MalformedGuideBadge
  /// A heading outside the README has a guide badge. Only README examples
  /// have one.
  GuideBadgeNotAllowed
  /// The guide badge links to another repository or host, or out of the
  /// repository.
  ForeignGuideLink(url: String)
  /// The tag in the guide badge link is not the release tag of the
  /// document (see `CheckContext`).
  WrongGuideTag(found: String, expected: String)
  /// The guide badge links to a path that is not a `.md` file under one of
  /// the guide directories. `guides` are those directories.
  NotAGuidePath(path: String, guides: List(String))
  /// The guide badge link has no `#<anchor>` for the section of the
  /// example.
  MissingGuideAnchor(path: String)
  /// The guide file of the guide badge does not exist in this repository.
  MissingGuideFile(path: String)
  /// The guide file has no heading whose anchor is `anchor` (without its
  /// `#`). See `heading_anchors`.
  GuideAnchorNotFound(path: String, anchor: String)
  /// The guide file has no tested snippet badge that links to `snippet`,
  /// so it does not show the example.
  ExampleNotInGuide(path: String, snippet: String)
}

/// One problem: the file, the 1-based line, and why.
pub type Problem {
  Problem(file: String, line: Int, reason: Reason)
}

/// The result of checking one or more documents.
///
/// `blocks_checked` counts the Gleam code blocks that were checked, and
/// `diff_blocks_checked` the diff blocks.
pub type Report {
  Report(blocks_checked: Int, diff_blocks_checked: Int, problems: List(Problem))
}

/// A link to GitHub's compare view of one file, read from a diff badge.
///
/// `anchor_digest` is the part of the anchor after `#diff-`.
pub type CompareLink {
  CompareLink(old_tag: String, new_tag: String, anchor_digest: String)
}

/// One hunk of a real git diff: its `@@` header line and the lines after
/// it, each with its `-`, `+` or space prefix.
pub type DiffHunk {
  DiffHunk(header: String, lines: List(String))
}

/// A run of lines in a diff block: an optional `@@` header line and the
/// lines after it, up to the next header. `first_line_number` is the line
/// number in the document of the first line after the header. The lines
/// of a block are consecutive, so the line at index `i` is at line
/// `first_line_number + i`.
type DiffSegment {
  DiffSegment(header: Option(Line), first_line_number: Int, lines: List(Line))
}

/// The kind of badge that a heading must end with.
type BadgeKind {
  SnippetBadge
  DiffBadge
}

/// A link to a tested snippet, read from a badge.
///
/// `anchor` is the line anchor with its `#`, or an empty string when the
/// link names the whole file.
pub type SnippetLink {
  SnippetLink(tag: String, path: String, anchor: String)
}

/// The badges of an example heading, read by `parse_example_heading`.
///
/// `snippet_address` is the link address of the tested snippet badge, and
/// `guide_badge` is what the heading has of the guide badge.
pub type ExampleHeading {
  ExampleHeading(snippet_address: String, guide_badge: GuideBadgeFound)
}

/// What an example heading has of the guide badge.
pub type GuideBadgeFound {
  /// The heading has no guide badge.
  NoGuideBadge
  /// The heading ends with the guide badge in the exact form, directly
  /// after the tested snippet badge. `address` is its link address.
  GuideBadgeLink(address: String)
  /// The heading has a guide badge, but not in the exact form, or not
  /// directly after the tested snippet badge.
  BrokenGuideBadge
}

/// A link to a section of a guide, read from a guide badge.
///
/// `anchor` is the fragment after the `#`, or an empty string when the
/// link has none.
pub type GuideLink {
  GuideLink(tag: String, path: String, anchor: String)
}

/// The part of a file that a badge link names.
pub type LineSelection {
  /// The link has no line anchor: the block is the whole file.
  WholeFile
  /// The link ends in `#L<start>-L<end>` (or `#L<n>`, where `start` and
  /// `end` are both `n`): the block is those lines, counted from 1.
  LineRange(start: Int, end: Int)
}

/// The opening line of a fenced code block.
type FenceOpener {
  FenceOpener(indent: Int, marker: String, length: Int, language: String)
}

/// A fenced code block. `content` has the fence indent removed.
/// `closing_line` is the line number of the closing fence, or the line
/// after the end of the document when there is none.
type FencedBlock {
  FencedBlock(
    opener: FenceOpener,
    opening_line: Int,
    content: List(Line),
    closing_line: Int,
    closed: Bool,
  )
}

/// Where the scan is: at the top level of a document, or inside an example
/// document in a `markdown` fence, where lines must not look like Gleam.
type ScanPlace {
  TopLevel
  InsideExample
}

/// Whether the example headings of a document carry the guide badge.
type GuideBadgeRule {
  /// The root README: each `gleam` block heading must end with the guide
  /// badge.
  GuideBadgeRequired
  /// Every other document: no heading may have the guide badge.
  GuideBadgeForbidden
}

/// The kind of a line in a Gleam source file.
type CommentKind {
  ItemComment
  ModuleComment
  NotDocComment
}

// ---------------------------------------------------------------------------
// Release notes and the changelog
// ---------------------------------------------------------------------------

/// Tells whether a release notes file is checked: its name is
/// `release-<version>.md` and the version is `checked_from_version` or
/// later. Versions are compared as numbers, so `10.0.0` is after `3.0.0`.
pub fn is_checked_release_notes(
  path: String,
  checked_from_version: Version,
) -> Bool {
  case release_notes_version(path) {
    Ok(version) -> is_checked_version(version, checked_from_version)
    Error(Nil) -> False
  }
}

/// Reads the version from the name of a release notes file, for example
/// `Version(3, 0, 0)` from `releases/release-3.0.0.md`.
pub fn release_notes_version(path: String) -> Result(Version, Nil) {
  use version_text <- result.try(release_notes_version_text(path))
  parse_release_version(version_text)
}

/// The version in the name of a release notes file, as it is written
/// there, for example `3.0.0-rc.1` from `releases/release-3.0.0-rc.1.md`.
fn release_notes_version_text(path: String) -> Result(String, Nil) {
  let file_name = path |> string.split("/") |> list.last |> result.unwrap(path)
  use rest <- result.try(remove_prefix(file_name, "release-"))
  use version_text <- result.try(remove_suffix(rest, ".md"))
  use _version <- result.map(parse_release_version(version_text))
  version_text
}

/// Reads `major.minor.patch`. A pre-release part after a `-`, such as
/// `-rc.1`, is ignored, so a pre-release counts as its release.
pub fn parse_release_version(text: String) -> Result(Version, Nil) {
  let core = case string.split_once(text, "-") {
    Ok(#(core, _pre_release)) -> core
    Error(Nil) -> text
  }
  case core |> string.split(".") |> list.try_map(parse_version_number) {
    Ok([major, minor, patch]) -> Ok(Version(major:, minor:, patch:))
    _ -> Error(Nil)
  }
}

fn parse_version_number(text: String) -> Result(Int, Nil) {
  use number <- result.try(int.parse(text))
  case number >= 0 && int.to_string(number) == text {
    True -> Ok(number)
    False -> Error(Nil)
  }
}

/// Compares two versions by major, then minor, then patch number.
pub fn compare_versions(first: Version, second: Version) -> Order {
  int.compare(first.major, second.major)
  |> order.break_tie(int.compare(first.minor, second.minor))
  |> order.break_tie(int.compare(first.patch, second.patch))
}

fn is_checked_version(version: Version, checked_from_version: Version) -> Bool {
  compare_versions(version, checked_from_version) != order.Lt
}

/// Checks the changelog. Its sections start at `## [<name>]` lines. The
/// sections of versions before `checked_from_version` are left out, and the
/// rest of the file is checked like a Markdown document. Each line keeps its
/// line number in the file.
pub fn check_changelog(
  file: String,
  text: String,
  context: CheckContext,
) -> Report {
  let #(_last_checked, marked_lines) =
    list.map_fold(numbered_lines(text, 1), True, fn(checked, line) {
      let checked =
        is_checked_from_line(line.text, checked, context.checked_from_version)
      #(checked, #(checked, line))
    })
  let lines =
    marked_lines
    |> list.filter(fn(marked) { marked.0 })
    |> list.map(fn(marked) { marked.1 })
  scan(lines, [], TopLevel, GuideBadgeForbidden, file, context, empty_report())
}

/// Whether a line is in a checked section: a section heading decides it
/// for the lines that follow, and any other line keeps the decision of the
/// line before it.
fn is_checked_from_line(
  text: String,
  checked_before: Bool,
  checked_from_version: Version,
) -> Bool {
  case changelog_section_name(text) {
    Ok(name) -> is_checked_changelog_section(name, checked_from_version)
    Error(Nil) -> checked_before
  }
}

/// Reads the name of a changelog section heading, for example `3.0.0` from
/// `## [3.0.0] - 2026-11-20`.
pub fn changelog_section_name(text: String) -> Result(String, Nil) {
  use rest <- result.try(remove_prefix(text, "## ["))
  use #(name, _after) <- result.map(string.split_once(rest, "]"))
  name
}

/// Tells whether a changelog section is checked: `Unreleased`, a version
/// from `checked_from_version` on, or a name that is not a version.
pub fn is_checked_changelog_section(
  name: String,
  checked_from_version: Version,
) -> Bool {
  case parse_release_version(name) {
    Ok(version) -> is_checked_version(version, checked_from_version)
    Error(Nil) -> True
  }
}

fn remove_prefix(text: String, prefix: String) -> Result(String, Nil) {
  case string.starts_with(text, prefix) {
    True -> Ok(string.drop_start(text, string.length(prefix)))
    False -> Error(Nil)
  }
}

fn remove_suffix(text: String, suffix: String) -> Result(String, Nil) {
  case string.ends_with(text, suffix) {
    True -> Ok(string.drop_end(text, string.length(suffix)))
    False -> Error(Nil)
  }
}

// ---------------------------------------------------------------------------
// The release notes template
// ---------------------------------------------------------------------------

/// Whether the release notes template requires a section.
pub type SectionPresence {
  /// The file must have the section. For a choice of headings, it must
  /// have one of them.
  RequiredSection
  /// The file may leave the section out.
  OptionalSection
}

/// A `##` heading that the release notes template allows.
///
/// `name` is the text of the heading after `## `. `subsections` are the
/// `###` headings that the section must have when the file has it.
pub type SectionHeading {
  SectionHeading(name: String, subsections: List(String))
}

/// One place in the order of the release notes template. `choices` are
/// the headings that can fill the place, and a file has one of them at
/// most. With `RequiredSection`, a file has exactly one of them.
pub type TemplateSection {
  TemplateSection(choices: List(SectionHeading), presence: SectionPresence)
}

/// The text after the version in the title of release notes. The title is
/// `# <Name> <version> Release Notes`.
pub const release_notes_title_end = " Release Notes"

/// The start of the line that gives the release date of release notes.
pub const release_date_prefix = "**Release Date:**"

/// The `##` sections of the release notes template, in order. This is the
/// only place that holds the template. `check_release_notes_template`
/// reads it, and the "Release notes template" guide of this package shows
/// it.
///
/// `Upgrading` is for a release that replaces an earlier one, and must
/// have a `### Migration Guide`. `Installing` is for a first release.
pub const release_notes_template = [
  TemplateSection([SectionHeading("Key Highlights", [])], RequiredSection),
  TemplateSection([SectionHeading("What's New", [])], RequiredSection),
  TemplateSection([SectionHeading("Deprecated", [])], OptionalSection),
  TemplateSection([SectionHeading("Removed", [])], OptionalSection),
  TemplateSection([SectionHeading("Bug Fixes", [])], OptionalSection),
  TemplateSection([SectionHeading("Known Limits", [])], OptionalSection),
  TemplateSection([SectionHeading("Testing", [])], RequiredSection),
  TemplateSection(
    [
      SectionHeading("Upgrading", ["Migration Guide"]),
      SectionHeading("Installing", []),
    ],
    RequiredSection,
  ),
  TemplateSection([SectionHeading("Acknowledgements", [])], OptionalSection),
  TemplateSection([SectionHeading("Documentation", [])], RequiredSection),
  TemplateSection([SectionHeading("Community", [])], RequiredSection),
]

/// A heading of release notes: its line number and its text, without the
/// `#` marks and without trailing HTML such as a badge link.
type HeadingLine {
  HeadingLine(line: Int, name: String)
}

/// A `##` section of release notes that is in the template. `place` is its
/// index in `release_notes_template`.
type FoundSection {
  FoundSection(place: Int, name: String, line: Int)
}

/// The state of the walk over the `##` headings of release notes.
/// `found` holds the first section found for each place, nearest first.
/// `latest` is the section with the highest place so far.
type TemplateScan {
  TemplateScan(
    found: List(FoundSection),
    latest: Option(FoundSection),
    problems: List(Problem),
  )
}

/// Checks that release notes follow the release notes template.
///
/// Headings are read outside code fences only, and trailing HTML after a
/// heading, such as a badge link, is ignored. The rules are:
///
/// - The first line is `# <Name> <version> Release Notes`, where
///   `<version>` is the version in the file name and `<Name>` is any text.
/// - A line that starts with `**Release Date:**` comes after the title and
///   before the first `##` section.
/// - The `##` sections are only those of `release_notes_template`, each
///   one time at most, in its order, and each required one is there.
/// - Each section has the `###` headings that the template requires in it.
///
/// ## Parameters
///
/// - `file`: the path of the release notes, for example
///   `releases/release-3.0.0.md`. The title must use its version.
/// - `text`: the content of the release notes
///
/// ## Returns
///
/// Each problem, sorted by line, with the line where it is, or line 1 for
/// a missing title, release date or section. A missing `###` heading is at the line of its
/// `##` section. An empty list when the release notes follow the template.
pub fn check_release_notes_template(
  file: String,
  text: String,
) -> List(Problem) {
  let lines = numbered_lines(text, 1)
  let prose = prose_lines(lines, [])
  let headings = list.filter_map(prose, heading_at(_, "## "))
  let first_section_line =
    headings
    |> list.first
    |> result.map(fn(heading) { heading.line })
    |> result.unwrap(list.length(lines) + 1)
  let walk =
    list.fold(headings, TemplateScan([], None, []), fn(walk, heading) {
      add_section_heading(file, walk, heading)
    })
  list.flatten([
    title_problems(file, lines),
    release_date_problems(file, prose, first_section_line),
    list.reverse(walk.problems),
    missing_section_problems(file, walk.found),
    list.flat_map(list.reverse(walk.found), fn(section) {
      subsection_problems(file, prose, section)
    }),
  ])
  |> sort_problems
}

/// The lines of a document that are not in a code fence. A fence with no
/// closing fence runs to the end of the document.
fn prose_lines(remaining: List(Line), kept: List(Line)) -> List(Line) {
  case remaining {
    [] -> list.reverse(kept)
    [line, ..rest] -> prose_line(line, rest, kept)
  }
}

fn prose_line(line: Line, rest: List(Line), kept: List(Line)) -> List(Line) {
  case parse_fence_opener(line.text) {
    None -> prose_lines(rest, [line, ..kept])
    Some(opener) -> {
      let #(_content, _closing, after) = split_fence(opener, rest, [])
      prose_lines(after, kept)
    }
  }
}

/// Reads a heading that starts with `marker`, such as `## `.
fn heading_at(line: Line, marker: String) -> Result(HeadingLine, Nil) {
  use rest <- result.map(remove_prefix(line.text, marker))
  let name = case string.split_once(rest, " <") {
    Ok(#(name, _html)) -> name
    Error(Nil) -> rest
  }
  HeadingLine(line: line.number, name: string.trim(name))
}

fn title_problems(file: String, lines: List(Line)) -> List(Problem) {
  let title =
    lines
    |> list.first
    |> result.map(fn(line) { line.text })
    |> result.unwrap("")
  let version = result.unwrap(release_notes_version_text(file), "<version>")
  case is_release_notes_title(title, version) {
    True -> []
    False -> [
      Problem(file:, line: 1, reason: ReleaseNotesTitleMismatch(title, version)),
    ]
  }
}

fn is_release_notes_title(title: String, version: String) -> Bool {
  title
  |> remove_prefix("# ")
  |> result.try(remove_suffix(_, " " <> version <> release_notes_title_end))
  |> result.map(fn(name) { string.trim(name) != "" })
  |> result.unwrap(False)
}

fn release_date_problems(
  file: String,
  prose: List(Line),
  first_section_line: Int,
) -> List(Problem) {
  let has_release_date =
    list.any(prose, fn(line) {
      line.number > 1
      && line.number < first_section_line
      && string.starts_with(line.text, release_date_prefix)
    })
  case has_release_date {
    True -> []
    False -> [Problem(file:, line: 1, reason: MissingReleaseDate)]
  }
}

fn indexed_template() -> List(#(Int, TemplateSection)) {
  list.index_map(release_notes_template, fn(section, index) {
    #(index, section)
  })
}

fn template_place(name: String) -> Result(Int, Nil) {
  indexed_template()
  |> list.find(fn(entry) {
    list.any({ entry.1 }.choices, fn(choice) { choice.name == name })
  })
  |> result.map(fn(entry) { entry.0 })
}

fn add_section_heading(
  file: String,
  walk: TemplateScan,
  heading: HeadingLine,
) -> TemplateScan {
  case template_place(heading.name) {
    Error(Nil) ->
      add_template_problem(
        walk,
        Problem(
          file:,
          line: heading.line,
          reason: UnknownReleaseNotesSection(heading.name),
        ),
      )
    Ok(place) ->
      add_known_section(
        file,
        walk,
        FoundSection(place:, name: heading.name, line: heading.line),
      )
  }
}

fn add_template_problem(walk: TemplateScan, problem: Problem) -> TemplateScan {
  TemplateScan(..walk, problems: [problem, ..walk.problems])
}

fn add_known_section(
  file: String,
  walk: TemplateScan,
  section: FoundSection,
) -> TemplateScan {
  case list.find(walk.found, fn(earlier) { earlier.place == section.place }) {
    Ok(earlier) ->
      add_template_problem(
        walk,
        Problem(
          file:,
          line: section.line,
          reason: second_section_reason(earlier, section),
        ),
      )
    Error(Nil) -> add_new_section(file, walk, section)
  }
}

fn second_section_reason(
  earlier: FoundSection,
  section: FoundSection,
) -> Reason {
  case earlier.name == section.name {
    True ->
      RepeatedReleaseNotesSection(
        section: section.name,
        first_line: earlier.line,
      )
    False ->
      ConflictingReleaseNotesSections(
        section: section.name,
        other: earlier.name,
      )
  }
}

fn add_new_section(
  file: String,
  walk: TemplateScan,
  section: FoundSection,
) -> TemplateScan {
  let found = [section, ..walk.found]
  case walk.latest {
    Some(latest) if latest.place > section.place ->
      TemplateScan(..walk, found:)
      |> add_template_problem(Problem(
        file:,
        line: section.line,
        reason: ReleaseNotesSectionOutOfOrder(
          section: section.name,
          after: latest.name,
        ),
      ))
    _ -> TemplateScan(..walk, found:, latest: Some(section))
  }
}

fn missing_section_problems(
  file: String,
  found: List(FoundSection),
) -> List(Problem) {
  indexed_template()
  |> list.filter(fn(entry) {
    { entry.1 }.presence == RequiredSection
    && !list.any(found, fn(section) { section.place == entry.0 })
  })
  |> list.map(fn(entry) {
    Problem(file:, line: 1, reason: missing_section_reason(entry.1))
  })
}

fn missing_section_reason(section: TemplateSection) -> Reason {
  case section.choices {
    [only] -> MissingReleaseNotesSection(only.name)
    choices ->
      MissingReleaseNotesChoice(list.map(choices, fn(choice) { choice.name }))
  }
}

/// The `###` headings that the template requires in a section, and that
/// the section does not have. The section runs to the next `##` heading.
fn subsection_problems(
  file: String,
  prose: List(Line),
  section: FoundSection,
) -> List(Problem) {
  let present =
    prose
    |> list.drop_while(fn(line) { line.number <= section.line })
    |> list.take_while(fn(line) { result.is_error(heading_at(line, "## ")) })
    |> list.filter_map(heading_at(_, "### "))
    |> list.map(fn(heading) { heading.name })
  required_subsections(section.name)
  |> list.filter(fn(name) { !list.contains(present, name) })
  |> list.map(fn(name) {
    Problem(
      file:,
      line: section.line,
      reason: MissingReleaseNotesSubsection(
        section: section.name,
        subsection: name,
      ),
    )
  })
}

fn required_subsections(name: String) -> List(String) {
  release_notes_template
  |> list.flat_map(fn(section) { section.choices })
  |> list.find(fn(choice) { choice.name == name })
  |> result.map(fn(choice) { choice.subsections })
  |> result.unwrap([])
}

// ---------------------------------------------------------------------------
// Reports
// ---------------------------------------------------------------------------

/// Sorts problems by file, then by line. Problems on the same line keep
/// their order.
pub fn sort_problems(problems: List(Problem)) -> List(Problem) {
  list.sort(problems, compare_problems)
}

fn compare_problems(first: Problem, second: Problem) -> Order {
  order.break_tie(
    string.compare(first.file, second.file),
    int.compare(first.line, second.line),
  )
}

/// The last line of the output, for example
/// `412 blocks and 5 diff blocks checked in 230 files, 0 problems`.
pub fn summary(
  blocks: Int,
  diff_blocks: Int,
  files: Int,
  problems: Int,
) -> String {
  int.to_string(blocks)
  <> " blocks and "
  <> int.to_string(diff_blocks)
  <> " diff blocks checked in "
  <> int.to_string(files)
  <> " files, "
  <> int.to_string(problems)
  <> " problems"
}

/// Describes a problem in one line, as `file:line: reason`.
pub fn describe_problem(problem: Problem, project: Project) -> String {
  problem.file
  <> ":"
  <> int.to_string(problem.line)
  <> ": "
  <> describe_reason(problem.reason, project)
}

/// The end of the message of a wrong tag: where the expected tag comes
/// from.
fn tag_rule(project: Project) -> String {
  " (the docs of " <> project.name <> " use the version in gleam.toml)"
}

/// The address of the GitHub repository of a project, for example
/// `https://github.com/TrustBound/dream`.
pub fn repository_url(repository: GitHubRepository) -> String {
  "https://github.com/" <> repository.owner <> "/" <> repository.name
}

/// Describes why a code block fails the check.
pub fn describe_reason(reason: Reason, project: Project) -> String {
  case reason {
    MissingBadgeHeading ->
      "this gleam code block has no heading with the tested snippet badge directly above it (one blank line between is allowed)"
    OldTestedSourceLine ->
      "the old \"🧪 Tested source\" line is not used now; put the tested snippet badge at the end of the heading above the code block"
    MalformedBadge ->
      "the tested snippet badge is not in the exact format; copy it from "
      <> project.badge_guide
    ForeignLink(url:) ->
      "the badge link "
      <> url
      <> " does not point at a file in "
      <> repository_url(project.repository)
    WrongTag(found:, expected:) ->
      "the badge link uses the tag "
      <> found
      <> ", but this file must link at the tag "
      <> expected
      <> tag_rule(project)
    MissingFile(path:) ->
      "the badge links to "
      <> path
      <> ", which is not a file in this repository"
    UnreadableFile(path:, reason:) ->
      "cannot read " <> path <> ": " <> simplifile.describe_error(reason)
    MalformedLineRange(anchor:) ->
      "the line anchor " <> anchor <> " is not #L<n> or #L<start>-L<end>"
    ReversedLineRange(start:, end:) ->
      "the line range starts at line "
      <> int.to_string(start)
      <> ", after its end at line "
      <> int.to_string(end)
    LineRangePastEnd(end:, line_count:) ->
      "the line range ends at line "
      <> int.to_string(end)
      <> ", but the file has "
      <> int.to_string(line_count)
      <> " lines"
    BlockDiffers(path:, anchor:, first_difference_line:) ->
      "the code block is not the same as "
      <> path
      <> anchor
      <> "; the first difference is at line "
      <> int.to_string(first_difference_line)
    HiddenGleamCode(language:) ->
      "this line looks like Gleam code in "
      <> describe_fence_language(language)
      <> "; put Gleam code in a gleam block with the tested snippet badge"
    UnclosedFence -> "this code fence has no closing fence"
    MissingDiffBadgeHeading ->
      "this diff block has no heading with the tested diff badge directly above it (one blank line between is allowed)"
    MalformedDiffBadge ->
      "the tested diff badge is not in the exact format; copy it from "
      <> project.badge_guide
    NotCompareLink(url:) ->
      "the diff badge link "
      <> url
      <> " is not "
      <> repository_url(project.repository)
      <> "/compare/<old tag>...<new tag>#diff-<digest>"
    WrongNewTag(found:, expected:) ->
      "the compare link ends at the tag "
      <> found
      <> ", but this file must use the new tag "
      <> expected
      <> tag_rule(project)
    MissingDiffFileHeader ->
      "the diff block does not start with \"--- a/<path>\" and \"+++ b/<path>\" for one path of letters, digits and . _ - /"
    EmptyDiffBlock -> "the diff block has no diff lines after its file header"
    WrongDiffAnchor(path:, expected:) ->
      "the compare link anchor is not the one for "
      <> path
      <> "; use "
      <> expected
    MissingOldTag(tag:) ->
      "the tag "
      <> tag
      <> " is not in this clone; fetch the tags with \"git fetch --tags\" (a shallow clone has none)"
    GitUnavailable(error:) ->
      "cannot read the git diff: " <> git.describe_error(error)
    NoDiffForPath(path:, old_tag:) ->
      path <> " has no changes since the tag " <> old_tag
    HunkHeaderNotFound(header:) ->
      "the hunk header "
      <> header
      <> " is not a hunk header of the real diff, or it is out of order"
    DiffLineNotFound(path:, old_tag:) ->
      "this line is not in \"git diff "
      <> old_tag
      <> " -- "
      <> path
      <> "\" at this place; a diff block shows lines of the real diff, in order and contiguous within a hunk"
    ReleaseNotesTitleMismatch(found:, version:) ->
      "the first line is \""
      <> found
      <> "\", but the template wants the title \"# <Name> "
      <> version
      <> release_notes_title_end
      <> "\""
      <> template_pointer(project)
    MissingReleaseDate ->
      "there is no line that starts with \""
      <> release_date_prefix
      <> "\" between the title and the first section, but the template wants one there"
      <> template_pointer(project)
    UnknownReleaseNotesSection(section:) ->
      quoted_section(section)
      <> " is not a section of the release notes template"
      <> template_pointer(project)
    ReleaseNotesSectionOutOfOrder(section:, after:) ->
      quoted_section(section)
      <> " comes after "
      <> quoted_section(after)
      <> ", but the template has it before "
      <> quoted_section(after)
      <> template_pointer(project)
    RepeatedReleaseNotesSection(section:, first_line:) ->
      quoted_section(section)
      <> " is in the file again (first at line "
      <> int.to_string(first_line)
      <> "), but the template has each section one time at most"
      <> template_pointer(project)
    ConflictingReleaseNotesSections(section:, other:) ->
      quoted_section(other)
      <> " and "
      <> quoted_section(section)
      <> " are both in the file, but the template allows only one of them"
      <> template_pointer(project)
    MissingReleaseNotesSection(section:) ->
      "the section "
      <> quoted_section(section)
      <> " is missing, but the template requires it"
      <> template_pointer(project)
    MissingReleaseNotesChoice(sections:) ->
      "neither "
      <> sections |> list.map(quoted_section) |> string.join(" nor ")
      <> " is in the file, but the template requires one of them"
      <> template_pointer(project)
    MissingReleaseNotesSubsection(section:, subsection:) ->
      quoted_section(section)
      <> " has no \"### "
      <> subsection
      <> "\", but the template requires it in that section"
      <> template_pointer(project)
    MissingGuideBadge ->
      "this README example heading has no guide badge after its tested snippet badge; copy the heading from "
      <> project.badge_guide
    MalformedGuideBadge ->
      "the guide badge is not in the exact format, or it is not directly after the tested snippet badge; copy the heading from "
      <> project.badge_guide
    GuideBadgeNotAllowed ->
      "this heading has a guide badge, but only README example headings have one; here the heading has only the tested snippet badge"
    ForeignGuideLink(url:) ->
      "the guide badge link "
      <> url
      <> " does not point at a file in "
      <> repository_url(project.repository)
    WrongGuideTag(found:, expected:) ->
      "the guide badge link uses the tag "
      <> found
      <> ", but this file must link at the tag "
      <> expected
      <> tag_rule(project)
    NotAGuidePath(path:, guides:) ->
      "the guide badge links to "
      <> path
      <> ", but it must link to a .md file under "
      <> string.join(guides, " or ")
    MissingGuideAnchor(path:) ->
      "the guide badge link to "
      <> path
      <> " has no #<anchor>, but it must name the guide section of this example"
    MissingGuideFile(path:) ->
      "the guide badge links to "
      <> path
      <> ", which is not a file in this repository"
    GuideAnchorNotFound(path:, anchor:) ->
      "the guide badge links to the anchor #"
      <> anchor
      <> ", but "
      <> path
      <> " has no heading with that anchor"
    ExampleNotInGuide(path:, snippet:) ->
      path
      <> " has no tested snippet badge that links to "
      <> snippet
      <> ", but the guide of a README example must show that example"
  }
}

/// The end of each release notes template message: where the template is
/// written.
fn template_pointer(project: Project) -> String {
  "; see \"Release notes template\" in " <> project.release_notes_guide
}

fn quoted_section(section: String) -> String {
  "\"## " <> section <> "\""
}

fn describe_fence_language(language: String) -> String {
  case language {
    "" -> "a code fence with no language"
    _ -> "a " <> language <> " code fence"
  }
}

fn merge_reports(reports: List(Report)) -> Report {
  list.fold(reports, empty_report(), add_report)
}

fn add_report(total: Report, report: Report) -> Report {
  Report(
    blocks_checked: total.blocks_checked + report.blocks_checked,
    diff_blocks_checked: total.diff_blocks_checked + report.diff_blocks_checked,
    problems: list.append(total.problems, report.problems),
  )
}

fn problems_report(problems: List(Problem)) -> Report {
  Report(blocks_checked: 0, diff_blocks_checked: 0, problems:)
}

// ---------------------------------------------------------------------------
// Documents
// ---------------------------------------------------------------------------

/// Checks every fenced code block in a Markdown document.
///
/// ## Parameters
///
/// - `file`: the path of the document, used in each problem
/// - `text`: the content of the document
/// - `context`: the project, the snippet files and git (see `CheckContext`)
///
/// ## Returns
///
/// A `Report` with the number of Gleam blocks and diff blocks checked, and
/// each problem found, in the order of the document.
///
/// ## Examples
///
/// ### Check one document <a href="https://github.com/TrustBound/dream_snippets/blob/1.0.0/test/snippets/guide_check_markdown.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_snippets/check.{
///   type Report, CheckContext, GitHubRepository, Project, Version,
/// }
/// import dream_snippets/git
/// import simplifile
///
/// pub fn check_guide(guide: String) -> Report {
///   let project =
///     Project(
///       name: "my_app",
///       version: "1.2.0",
///       repository: GitHubRepository(owner: "me", name: "my_app"),
///       badge_guide: "CONTRIBUTING.md",
///       release_notes_guide: "CONTRIBUTING.md",
///       guides: ["docs/guides"],
///     )
///   let context =
///     CheckContext(
///       project:,
///       checked_from_version: Version(1, 0, 0),
///       read_source: simplifile.read,
///       tag_exists: fn(_tag) { Error(git.GitNotFound) },
///       diff_from_tag: fn(_tag, _path) { Error(git.GitNotFound) },
///     )
///   check.check_markdown("docs/guide.md", guide, context)
/// }
/// ```
pub fn check_markdown(
  file: String,
  text: String,
  context: CheckContext,
) -> Report {
  scan(
    numbered_lines(text, 1),
    [],
    TopLevel,
    GuideBadgeForbidden,
    file,
    context,
    empty_report(),
  )
}

/// Checks the root README of a project: every fenced code block, as
/// `check_markdown` does, and the guide badge of each example.
///
/// In the README, the heading of each `gleam` block has two badges: the
/// tested snippet badge, then one space and the guide badge. Both images
/// float right, so the guide badge shows to the left of the tested snippet
/// badge:
///
/// ```markdown
/// ### Title <a href="https://github.com/<owner>/<repo>/blob/<version>/<snippet path>"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a> <a href="https://github.com/<owner>/<repo>/blob/<version>/docs/guides/<name>.md#<anchor>"><img align="right" alt="Guide" src="https://img.shields.io/badge/%F0%9F%93%96_read-guide-blue.svg?style=flat-square"></a>
/// ```
///
/// The guide badge links to a `.md` file under one of the `guides`
/// directories of the project, at the release tag, with the anchor of a
/// heading of that guide (see `heading_anchors`). The guide must have a
/// tested snippet badge that links to the same snippet file, so it shows
/// the example. The guide badge is checked when the tested snippet badge
/// is a link of the repository. Its problems are at the line of the
/// heading. A `diff` block heading has no guide badge.
pub fn check_readme(
  file: String,
  text: String,
  context: CheckContext,
) -> Report {
  scan(
    numbered_lines(text, 1),
    [],
    TopLevel,
    GuideBadgeRequired,
    file,
    context,
    empty_report(),
  )
}

/// Checks every fenced code block in the `///` and `////` doc comments of
/// a Gleam source file.
///
/// Each run of doc comment lines of one kind is read as a Markdown
/// document: the comment prefix (`/// `, `//// `, or `///` and `////` on a
/// blank comment line) is removed, and each line keeps its line number in
/// the file. Leading spaces before the prefix are allowed, so indented doc
/// comments are checked too.
pub fn check_gleam_source(
  file: String,
  text: String,
  context: CheckContext,
) -> Report {
  numbered_lines(text, 1)
  |> list.map(classify_comment_line)
  |> list.chunk(by: fn(classified) { classified.0 })
  |> list.filter_map(comment_run)
  |> list.map(fn(run) {
    scan(run, [], TopLevel, GuideBadgeForbidden, file, context, empty_report())
  })
  |> merge_reports
}

fn empty_report() -> Report {
  problems_report([])
}

fn numbered_lines(text: String, first_number: Int) -> List(Line) {
  text
  |> string.split("\n")
  |> list.index_map(fn(line_text, index) {
    Line(number: first_number + index, text: line_text)
  })
}

fn classify_comment_line(line: Line) -> #(CommentKind, Line) {
  let code = string.trim_start(line.text)
  let kind = comment_kind(code)
  let prefix_length = case kind {
    ModuleComment -> 4
    ItemComment -> 3
    NotDocComment -> 0
  }
  let comment_text = string.drop_start(code, prefix_length)
  let text = case string.starts_with(comment_text, " ") {
    True -> string.drop_start(comment_text, 1)
    False -> comment_text
  }
  #(kind, Line(..line, text:))
}

fn comment_kind(code: String) -> CommentKind {
  case code {
    "/////" <> _ -> NotDocComment
    "////" <> _ -> ModuleComment
    "///" <> _ -> ItemComment
    _ -> NotDocComment
  }
}

fn comment_run(run: List(#(CommentKind, Line))) -> Result(List(Line), Nil) {
  case run {
    [#(NotDocComment, _), ..] -> Error(Nil)
    _ -> Ok(list.map(run, fn(classified) { classified.1 }))
  }
}

// ---------------------------------------------------------------------------
// Fences
// ---------------------------------------------------------------------------

/// Walks the lines of one document. `above` holds the lines before the
/// current one, nearest first, so that a block can find its heading.
fn scan(
  remaining: List(Line),
  above: List(Line),
  place: ScanPlace,
  rule: GuideBadgeRule,
  file: String,
  context: CheckContext,
  report: Report,
) -> Report {
  case remaining {
    [] -> report
    [line, ..rest] ->
      scan_line(line, rest, above, place, rule, file, context, report)
  }
}

fn scan_line(
  line: Line,
  rest: List(Line),
  above: List(Line),
  place: ScanPlace,
  rule: GuideBadgeRule,
  file: String,
  context: CheckContext,
  report: Report,
) -> Report {
  case parse_fence_opener(line.text) {
    None -> {
      let report = add_report(report, check_prose_line(line, place, file))
      scan(rest, [line, ..above], place, rule, file, context, report)
    }
    Some(opener) -> {
      let #(raw_content, closing, after) = split_fence(opener, rest, [])
      let block =
        FencedBlock(
          opener:,
          opening_line: line.number,
          content: list.map(raw_content, fn(content_line) {
            Line(
              ..content_line,
              text: remove_indent(content_line.text, opener.indent),
            )
          }),
          closing_line: closing_line_number(line, raw_content, closing),
          closed: option.is_some(closing),
        )
      let report =
        add_report(
          report,
          check_block(block, above, after, rule, file, context),
        )
      let above =
        list.flatten([
          option_to_list(closing),
          list.reverse(raw_content),
          [line],
          above,
        ])
      scan(after, above, place, rule, file, context, report)
    }
  }
}

fn check_prose_line(line: Line, place: ScanPlace, file: String) -> Report {
  case place, looks_like_gleam(line.text) {
    InsideExample, True ->
      problems_report([
        Problem(file:, line: line.number, reason: HiddenGleamCode("markdown")),
      ])
    _, _ -> empty_report()
  }
}

fn closing_line_number(
  opening: Line,
  content: List(Line),
  closing: Option(Line),
) -> Int {
  case closing {
    Some(line) -> line.number
    None -> opening.number + list.length(content) + 1
  }
}

fn parse_fence_opener(text: String) -> Option(FenceOpener) {
  let trimmed = string.trim_start(text)
  let indent = string.length(text) - string.length(trimmed)
  let backticks = count_leading(trimmed, "`", 0)
  let tildes = count_leading(trimmed, "~", 0)
  case backticks >= 3, tildes >= 3 {
    True, _ -> fence_opener(trimmed, indent, "`", backticks)
    _, True -> fence_opener(trimmed, indent, "~", tildes)
    False, False -> None
  }
}

fn fence_opener(
  trimmed: String,
  indent: Int,
  marker: String,
  length: Int,
) -> Option(FenceOpener) {
  let info = string.trim(string.drop_start(trimmed, length))
  case marker == "`" && string.contains(info, "`") {
    True -> None
    False ->
      Some(FenceOpener(
        indent:,
        marker:,
        length:,
        language: string.lowercase(first_word(info)),
      ))
  }
}

fn first_word(text: String) -> String {
  case string.split_once(text, " ") {
    Ok(#(word, _)) -> word
    Error(Nil) -> text
  }
}

fn count_leading(text: String, character: String, count: Int) -> Int {
  case string.pop_grapheme(text) {
    Ok(#(first, rest)) if first == character ->
      count_leading(rest, character, count + 1)
    _ -> count
  }
}

fn is_fence_closer(text: String, opener: FenceOpener) -> Bool {
  let trimmed = string.trim(text)
  let run = count_leading(trimmed, opener.marker, 0)
  run >= opener.length && run == string.length(trimmed)
}

/// Splits the lines after an opening fence into the block content, the
/// closing fence (if any) and the lines after it.
fn split_fence(
  opener: FenceOpener,
  lines: List(Line),
  content: List(Line),
) -> #(List(Line), Option(Line), List(Line)) {
  case lines {
    [] -> #(list.reverse(content), None, [])
    [line, ..rest] -> split_fence_at(opener, line, rest, content)
  }
}

fn split_fence_at(
  opener: FenceOpener,
  line: Line,
  rest: List(Line),
  content: List(Line),
) -> #(List(Line), Option(Line), List(Line)) {
  case is_fence_closer(line.text, opener) {
    True -> #(list.reverse(content), Some(line), rest)
    False -> split_fence(opener, rest, [line, ..content])
  }
}

/// Removes up to `indent` leading spaces, as Markdown does for the lines
/// of an indented fence.
fn remove_indent(text: String, indent: Int) -> String {
  string.drop_start(text, int.min(indent, count_leading(text, " ", 0)))
}

// ---------------------------------------------------------------------------
// Blocks
// ---------------------------------------------------------------------------

fn check_block(
  block: FencedBlock,
  above: List(Line),
  after: List(Line),
  rule: GuideBadgeRule,
  file: String,
  context: CheckContext,
) -> Report {
  let unclosed = case block.closed {
    True -> []
    False -> [Problem(file:, line: block.opening_line, reason: UnclosedFence)]
  }
  let report = case block.opener.language {
    "gleam" ->
      Report(
        blocks_checked: 1,
        diff_blocks_checked: 0,
        problems: check_gleam_block(block, above, after, rule, file, context),
      )
    "diff" ->
      Report(
        blocks_checked: 0,
        diff_blocks_checked: 1,
        problems: check_diff_block(block, above, file, context),
      )
    "markdown" | "md" ->
      scan(
        block.content,
        [],
        InsideExample,
        rule,
        file,
        context,
        empty_report(),
      )
    language -> problems_report(hidden_gleam(block, language, file))
  }
  add_report(problems_report(unclosed), report)
}

fn hidden_gleam(
  block: FencedBlock,
  language: String,
  file: String,
) -> List(Problem) {
  case list.find(block.content, fn(line) { looks_like_gleam(line.text) }) {
    Ok(line) -> [
      Problem(file:, line: line.number, reason: HiddenGleamCode(language)),
    ]
    Error(Nil) -> []
  }
}

fn check_gleam_block(
  block: FencedBlock,
  above: List(Line),
  after: List(Line),
  rule: GuideBadgeRule,
  file: String,
  context: CheckContext,
) -> List(Problem) {
  let at_block = fn(reason) {
    Problem(file:, line: block.opening_line, reason:)
  }
  let old_line_below =
    old_tested_source_line(first_line_skipping_one_blank(after), file)
  let heading_problems = case first_line_skipping_one_blank(above) {
    None -> [at_block(MissingBadgeHeading)]
    Some(line) -> check_heading(line, block, rule, file, context)
  }
  list.append(heading_problems, old_line_below)
}

/// The nearest line, or the line after one blank line. A second blank
/// line is returned as it is, so the block then has no heading.
fn first_line_skipping_one_blank(lines: List(Line)) -> Option(Line) {
  case lines {
    [] -> None
    [line, ..rest] -> line_or_next_after_blank(line, rest)
  }
}

fn line_or_next_after_blank(line: Line, rest: List(Line)) -> Option(Line) {
  case is_blank(line.text), rest {
    False, _ -> Some(line)
    True, [next, ..] -> Some(next)
    True, [] -> None
  }
}

fn is_blank(text: String) -> Bool {
  string.trim(text) == ""
}

fn is_old_tested_source_line(text: String) -> Bool {
  string.contains(text, "Tested source")
}

fn old_tested_source_line(line: Option(Line), file: String) -> List(Problem) {
  line
  |> option_to_list
  |> list.filter(fn(found) { is_old_tested_source_line(found.text) })
  |> list.map(fn(found) {
    Problem(file:, line: found.number, reason: OldTestedSourceLine)
  })
}

fn check_heading(
  heading: Line,
  block: FencedBlock,
  rule: GuideBadgeRule,
  file: String,
  context: CheckContext,
) -> List(Problem) {
  case is_old_tested_source_line(heading.text) {
    True -> [Problem(file:, line: heading.number, reason: OldTestedSourceLine)]
    False -> example_heading_problems(heading, block, rule, file, context)
  }
}

/// The problems of the badges of an example heading. The problems of the
/// tested snippet badge are at the line of the block, and those of the
/// guide badge at the line of the heading.
fn example_heading_problems(
  heading: Line,
  block: FencedBlock,
  rule: GuideBadgeRule,
  file: String,
  context: CheckContext,
) -> List(Problem) {
  let at_line = fn(line) { fn(reason) { Problem(file:, line:, reason:) } }
  let parsed =
    parse_example_heading(heading.text)
    |> result.try(fn(example) {
      parse_snippet_link(example.snippet_address, context.project.repository)
      |> result.map(fn(link) { #(example, link) })
    })
  case parsed {
    Error(reason) -> [at_line(block.opening_line)(reason)]
    Ok(#(example, link)) ->
      list.append(
        list.map(check_link(link, block, context), at_line(block.opening_line)),
        list.map(
          guide_badge_reasons(example.guide_badge, link, rule, context),
          at_line(heading.number),
        ),
      )
  }
}

/// Reads a heading line that ends with the badge, and returns the link
/// address of the badge.
///
/// The line is a Markdown heading (`#` to `######`, a space and a title),
/// then `badge_start`, the address, and exactly `badge_end`.
pub fn parse_badge_heading(text: String) -> Result(String, Reason) {
  parse_heading_with_badge(text, SnippetBadge)
}

/// Reads a heading line that ends with the diff badge, and returns the link
/// address of the badge. The rules are those of `parse_badge_heading`, with
/// `diff_badge_end` in place of `badge_end`.
pub fn parse_diff_badge_heading(text: String) -> Result(String, Reason) {
  parse_heading_with_badge(text, DiffBadge)
}

/// Reads the heading of a `gleam` block: the tested snippet badge, and the
/// guide badge after it, if any.
///
/// When the last badge of the heading is a guide badge, the text before it
/// must be a heading that ends with the tested snippet badge (see
/// `parse_badge_heading`). The guide badge is `badge_start`, the address,
/// and exactly `guide_badge_end`. When the last badge is not a guide badge,
/// the whole heading must end with the tested snippet badge, and a guide
/// badge in another place is a `BrokenGuideBadge`.
///
/// ## Errors
///
/// The `Reason` of `parse_badge_heading` when the tested snippet badge is
/// missing or not in the exact format.
pub fn parse_example_heading(text: String) -> Result(ExampleHeading, Reason) {
  let trimmed = string.trim(text)
  let parts = string.split(trimmed, badge_start)
  let last = list.last(parts) |> result.unwrap("")
  let before_last =
    parts
    |> list.take(list.length(parts) - 1)
    |> string.join(badge_start)
  case string.contains(last, guide_badge_marker) {
    True -> example_heading(before_last, guide_badge_from(last))
    False -> example_heading(trimmed, guide_badge_elsewhere(trimmed))
  }
}

fn example_heading(
  snippet_heading: String,
  guide_badge: GuideBadgeFound,
) -> Result(ExampleHeading, Reason) {
  use snippet_address <- result.map(parse_badge_heading(snippet_heading))
  ExampleHeading(snippet_address:, guide_badge:)
}

/// Reads the last badge of a heading, which has the guide badge alt text.
fn guide_badge_from(badge: String) -> GuideBadgeFound {
  let address = remove_suffix(badge, guide_badge_end) |> result.unwrap("")
  case address == "" || string.contains(address, "\"") {
    True -> BrokenGuideBadge
    False -> GuideBadgeLink(address)
  }
}

fn guide_badge_elsewhere(heading: String) -> GuideBadgeFound {
  case string.contains(heading, guide_badge_marker) {
    True -> BrokenGuideBadge
    False -> NoGuideBadge
  }
}

/// Reads a guide badge link address into a guide link. The address must be
/// a file in `repository` on GitHub, as
/// `https://github.com/<owner>/<name>/blob/<tag>/<path>#<anchor>`, with a
/// path that stays inside the repository (the rule of
/// `parse_snippet_link`).
///
/// ## Errors
///
/// `ForeignGuideLink(address)` when the address names another repository
/// or host, or a path out of the repository.
pub fn parse_guide_link(
  address: String,
  repository: GitHubRepository,
) -> Result(GuideLink, Reason) {
  parse_snippet_link(address, repository)
  |> result.map(fn(link) {
    GuideLink(
      tag: link.tag,
      path: link.path,
      anchor: string.drop_start(link.anchor, 1),
    )
  })
  |> result.replace_error(ForeignGuideLink(address))
}

fn parse_heading_with_badge(
  text: String,
  kind: BadgeKind,
) -> Result(String, Reason) {
  let trimmed = string.trim(text)
  let hashes = count_leading(trimmed, "#", 0)
  let is_heading =
    hashes >= 1
    && hashes <= 6
    && string.starts_with(string.drop_start(trimmed, hashes), " ")
  case is_heading, string.split(trimmed, badge_start) {
    False, _ -> Error(missing_badge_reason(kind))
    True, [_no_badge] -> Error(badge_absent_reason(trimmed, kind))
    True, parts -> badge_address(parts, hashes, kind)
  }
}

fn badge_end_for(kind: BadgeKind) -> String {
  case kind {
    SnippetBadge -> badge_end
    DiffBadge -> diff_badge_end
  }
}

fn badge_alt_for(kind: BadgeKind) -> String {
  case kind {
    SnippetBadge -> "Tested snippet"
    DiffBadge -> "Tested diff"
  }
}

fn missing_badge_reason(kind: BadgeKind) -> Reason {
  case kind {
    SnippetBadge -> MissingBadgeHeading
    DiffBadge -> MissingDiffBadgeHeading
  }
}

fn malformed_badge_reason(kind: BadgeKind) -> Reason {
  case kind {
    SnippetBadge -> MalformedBadge
    DiffBadge -> MalformedDiffBadge
  }
}

fn badge_absent_reason(heading: String, kind: BadgeKind) -> Reason {
  case string.contains(heading, badge_alt_for(kind)) {
    True -> malformed_badge_reason(kind)
    False -> missing_badge_reason(kind)
  }
}

fn badge_address(
  parts: List(String),
  hashes: Int,
  kind: BadgeKind,
) -> Result(String, Reason) {
  let badge = list.last(parts) |> result.unwrap("")
  let title =
    parts
    |> list.take(list.length(parts) - 1)
    |> string.join(badge_start)
    |> string.drop_start(hashes)
    |> string.trim
  use address <- result.try(
    remove_suffix(badge, badge_end_for(kind))
    |> result.replace_error(badge_mismatch_reason(badge, kind)),
  )
  case title == "" || address == "" || string.contains(address, "\"") {
    True -> Error(malformed_badge_reason(kind))
    False -> Ok(address)
  }
}

fn badge_mismatch_reason(badge: String, kind: BadgeKind) -> Reason {
  case string.contains(badge, "<img") {
    True -> malformed_badge_reason(kind)
    False -> missing_badge_reason(kind)
  }
}

/// Reads a badge link address into a snippet link. The address must be a
/// file in `repository` on GitHub, as
/// `https://github.com/<owner>/<name>/blob/<tag>/<path>`, with a path that
/// stays inside the repository.
///
/// ## Errors
///
/// `ForeignLink(address)` when the address names another repository or
/// host, or a path out of the repository.
pub fn parse_snippet_link(
  address: String,
  repository: GitHubRepository,
) -> Result(SnippetLink, Reason) {
  use after_prefix <- result.try(
    remove_prefix(address, repository_url(repository) <> "/blob/")
    |> result.replace_error(ForeignLink(address)),
  )
  use #(tag, path_and_anchor) <- result.try(
    string.split_once(after_prefix, "/")
    |> result.replace_error(ForeignLink(address)),
  )
  let #(path, anchor) = split_anchor(path_and_anchor)
  case is_repository_path(path) {
    True -> Ok(SnippetLink(tag:, path:, anchor:))
    False -> Error(ForeignLink(address))
  }
}

fn split_anchor(text: String) -> #(String, String) {
  case string.split_once(text, "#") {
    Ok(#(path, fragment)) -> #(path, "#" <> fragment)
    Error(Nil) -> #(text, "")
  }
}

fn is_repository_path(path: String) -> Bool {
  let segments = string.split(path, "/")
  path != ""
  && !string.contains(path, "?")
  && !list.contains(segments, "..")
  && !list.contains(segments, ".")
  && !list.contains(segments, "")
}

/// Reads a line anchor: an empty string for the whole file, `#L<n>` for
/// one line, or `#L<start>-L<end>` for a range. Line numbers are positive
/// and have no leading zero.
pub fn parse_line_selection(anchor: String) -> Result(LineSelection, Reason) {
  case anchor {
    "" -> Ok(WholeFile)
    "#L" <> lines -> parse_line_range(lines, anchor)
    _ -> Error(MalformedLineRange(anchor))
  }
}

fn parse_line_range(
  lines: String,
  anchor: String,
) -> Result(LineSelection, Reason) {
  let numbers = case string.split_once(lines, "-L") {
    Ok(#(start, end)) -> #(parse_line_number(start), parse_line_number(end))
    Error(Nil) -> #(parse_line_number(lines), parse_line_number(lines))
  }
  case numbers {
    #(Ok(start), Ok(end)) if start > end ->
      Error(ReversedLineRange(start:, end:))
    #(Ok(start), Ok(end)) -> Ok(LineRange(start:, end:))
    _ -> Error(MalformedLineRange(anchor))
  }
}

fn parse_line_number(text: String) -> Result(Int, Nil) {
  use number <- result.try(int.parse(text))
  case number > 0 && int.to_string(number) == text {
    True -> Ok(number)
    False -> Error(Nil)
  }
}

/// Checks one snippet link against its block. The tag is checked on its
/// own; the line anchor, the file and the content are checked in order,
/// each only when the one before it passed.
fn check_link(
  link: SnippetLink,
  block: FencedBlock,
  context: CheckContext,
) -> List(Reason) {
  let release_tag = context.project.version
  let tag_problems = case link.tag == release_tag {
    True -> []
    False -> [WrongTag(found: link.tag, expected: release_tag)]
  }
  let content_problems = case check_content(link, block, context) {
    Ok(Nil) -> []
    Error(reason) -> [reason]
  }
  list.append(tag_problems, content_problems)
}

fn check_content(
  link: SnippetLink,
  block: FencedBlock,
  context: CheckContext,
) -> Result(Nil, Reason) {
  use selection <- result.try(parse_line_selection(link.anchor))
  use source <- result.try(
    context.read_source(link.path)
    |> result.map_error(fn(error) { source_error_reason(link.path, error) }),
  )
  use expected <- result.try(expected_lines(source, selection, block))
  let block_lines = list.map(block.content, fn(line) { line.text })
  let actual = case selection {
    WholeFile -> list.append(block_lines, [""])
    LineRange(..) -> block_lines
  }
  case first_difference(actual, expected, 0) {
    None -> Ok(Nil)
    Some(index) ->
      Error(BlockDiffers(
        path: link.path,
        anchor: link.anchor,
        first_difference_line: document_line(block, index),
      ))
  }
}

fn source_error_reason(path: String, error: simplifile.FileError) -> Reason {
  case error {
    simplifile.Enoent | simplifile.Eisdir | simplifile.Enotdir ->
      MissingFile(path)
    _ -> UnreadableFile(path:, reason: error)
  }
}

/// The lines that the block must have.
///
/// For a line range, they are the lines of that range. For the whole file,
/// they are the file split on each newline, so the last item is the empty
/// text after the final newline; the caller adds an empty item to the
/// block lines to match it. A whole-file block may leave out the leading
/// `////` module comment and the blank line after it: it is compared
/// without them when its first line is not a `////` line.
fn expected_lines(
  source: String,
  selection: LineSelection,
  block: FencedBlock,
) -> Result(List(String), Reason) {
  case selection {
    WholeFile -> Ok(whole_file_lines(source, block))
    LineRange(start:, end:) -> range_lines(source, start, end)
  }
}

fn whole_file_lines(source: String, block: FencedBlock) -> List(String) {
  let lines = string.split(source, "\n")
  case starts_with_module_comment(block) {
    True -> lines
    False -> without_module_comment(lines)
  }
}

fn starts_with_module_comment(block: FencedBlock) -> Bool {
  case block.content {
    [first, ..] -> string.starts_with(first.text, "////")
    [] -> False
  }
}

fn without_module_comment(lines: List(String)) -> List(String) {
  let rest =
    list.drop_while(lines, fn(line) { string.starts_with(line, "////") })
  case list.length(rest) == list.length(lines), rest {
    True, _ -> lines
    False, ["", ..after_blank] -> after_blank
    False, _ -> rest
  }
}

fn range_lines(
  source: String,
  start: Int,
  end: Int,
) -> Result(List(String), Reason) {
  let lines = source_lines(source)
  let line_count = list.length(lines)
  case end > line_count {
    True -> Error(LineRangePastEnd(end:, line_count:))
    False -> Ok(lines |> list.drop(start - 1) |> list.take(end - start + 1))
  }
}

/// The lines of a file as GitHub numbers them: a final newline does not
/// start another line.
fn source_lines(source: String) -> List(String) {
  let content = case string.ends_with(source, "\n") {
    True -> string.drop_end(source, 1)
    False -> source
  }
  string.split(content, "\n")
}

fn first_difference(
  actual: List(String),
  expected: List(String),
  index: Int,
) -> Option(Int) {
  case actual, expected {
    [], [] -> None
    [first_actual, ..rest_actual], [first_expected, ..rest_expected]
      if first_actual == first_expected
    -> first_difference(rest_actual, rest_expected, index + 1)
    _, _ -> Some(index)
  }
}

fn document_line(block: FencedBlock, index: Int) -> Int {
  case list.drop(block.content, index) {
    [line, ..] -> line.number
    [] -> block.closing_line
  }
}

// ---------------------------------------------------------------------------
// The guide badge
// ---------------------------------------------------------------------------

/// The problems of the guide badge of one example heading. `snippet` is
/// the link of the tested snippet badge of the same heading.
fn guide_badge_reasons(
  guide_badge: GuideBadgeFound,
  snippet: SnippetLink,
  rule: GuideBadgeRule,
  context: CheckContext,
) -> List(Reason) {
  case rule, guide_badge {
    GuideBadgeForbidden, NoGuideBadge -> []
    GuideBadgeForbidden, _ -> [GuideBadgeNotAllowed]
    GuideBadgeRequired, NoGuideBadge -> [MissingGuideBadge]
    GuideBadgeRequired, BrokenGuideBadge -> [MalformedGuideBadge]
    GuideBadgeRequired, GuideBadgeLink(address:) ->
      guide_link_reasons(address, snippet, context)
  }
}

/// Checks a guide badge link. The tag is checked on its own. The path, the
/// anchor, the guide file, the heading of the anchor and the example in the
/// guide are checked in order, each only when the one before it passed.
fn guide_link_reasons(
  address: String,
  snippet: SnippetLink,
  context: CheckContext,
) -> List(Reason) {
  case parse_guide_link(address, context.project.repository) {
    Error(reason) -> [reason]
    Ok(link) ->
      list.append(
        guide_tag_reasons(link, context.project.version),
        check_guide(link, snippet, context)
          |> result_to_reasons,
      )
  }
}

fn guide_tag_reasons(link: GuideLink, release_tag: String) -> List(Reason) {
  case link.tag == release_tag {
    True -> []
    False -> [WrongGuideTag(found: link.tag, expected: release_tag)]
  }
}

fn result_to_reasons(checked: Result(Nil, Reason)) -> List(Reason) {
  case checked {
    Ok(Nil) -> []
    Error(reason) -> [reason]
  }
}

fn check_guide(
  link: GuideLink,
  snippet: SnippetLink,
  context: CheckContext,
) -> Result(Nil, Reason) {
  let guides = context.project.guides
  use Nil <- result.try(require(
    is_guide_path(link.path, guides),
    NotAGuidePath(path: link.path, guides:),
  ))
  use Nil <- result.try(require(
    link.anchor != "",
    MissingGuideAnchor(link.path),
  ))
  use guide <- result.try(
    context.read_source(link.path)
    |> result.map_error(fn(error) { guide_error_reason(link.path, error) }),
  )
  use Nil <- result.try(require(
    list.contains(heading_anchors(guide), decode_anchor(link.anchor)),
    GuideAnchorNotFound(path: link.path, anchor: link.anchor),
  ))
  require(
    shows_snippet(guide, snippet.path, context.project.repository),
    ExampleNotInGuide(path: link.path, snippet: snippet.path),
  )
}

fn require(condition: Bool, reason: Reason) -> Result(Nil, Reason) {
  case condition {
    True -> Ok(Nil)
    False -> Error(reason)
  }
}

/// Tells whether a path is a `.md` file under one of the guide
/// directories. A trailing `/` of a directory is ignored.
pub fn is_guide_path(path: String, guides: List(String)) -> Bool {
  string.ends_with(path, ".md")
  && list.any(guides, fn(directory) {
    string.starts_with(path, remove_trailing_slashes(directory) <> "/")
  })
}

fn remove_trailing_slashes(path: String) -> String {
  case remove_suffix(path, "/") {
    Ok(shorter) -> remove_trailing_slashes(shorter)
    Error(Nil) -> path
  }
}

fn guide_error_reason(path: String, error: simplifile.FileError) -> Reason {
  case source_error_reason(path, error) {
    MissingFile(path:) -> MissingGuideFile(path)
    reason -> reason
  }
}

/// An anchor as the browser shows it can be percent-encoded, for example
/// `caf%C3%A9` for `café`. It is decoded before it is compared.
fn decode_anchor(anchor: String) -> String {
  uri.percent_decode(anchor) |> result.unwrap(anchor)
}

/// Tells whether a document has a heading, outside code fences, with a
/// tested snippet badge that links to `snippet_path` in `repository`. The
/// tag and the line range of the link are not compared.
fn shows_snippet(
  text: String,
  snippet_path: String,
  repository: GitHubRepository,
) -> Bool {
  numbered_lines(text, 1)
  |> prose_lines([])
  |> list.any(fn(line) {
    parse_badge_heading(line.text)
    |> result.try(parse_snippet_link(_, repository))
    |> result.map(fn(link) { link.path == snippet_path })
    |> result.unwrap(False)
  })
}

// ---------------------------------------------------------------------------
// Heading anchors
// ---------------------------------------------------------------------------

/// The anchors of the headings of a Markdown document, in order, as GitHub
/// makes them.
///
/// A heading is a line outside code fences that starts with 1 to 6 `#`
/// and a space. A closing run of `#` after a space is not part of its
/// text. Each heading gets the anchor `heading_slug` of its text. When an
/// anchor is already used by an earlier heading, the second heading gets
/// the anchor with `-1` after it, the third `-2`, and so on.
pub fn heading_anchors(markdown: String) -> List(String) {
  let #(_seen, anchors) =
    numbered_lines(markdown, 1)
    |> prose_lines([])
    |> list.filter_map(fn(line) { heading_text(line.text) })
    |> list.map(heading_slug)
    |> list.map_fold([], fn(seen, slug) {
      #(
        [slug, ..seen],
        numbered_slug(slug, list.count(seen, fn(earlier) { earlier == slug })),
      )
    })
  anchors
}

fn numbered_slug(slug: String, earlier_count: Int) -> String {
  case earlier_count {
    0 -> slug
    _ -> slug <> "-" <> int.to_string(earlier_count)
  }
}

/// The text of a heading line, without its `#` marks and without a closing
/// run of `#`.
fn heading_text(text: String) -> Result(String, Nil) {
  let hashes = count_leading(text, "#", 0)
  let rest = string.drop_start(text, hashes)
  case hashes >= 1 && hashes <= 6 && string.starts_with(rest, " ") {
    True -> Ok(remove_closing_hashes(string.trim(rest)))
    False -> Error(Nil)
  }
}

fn remove_closing_hashes(text: String) -> String {
  let hashes = count_leading(string.reverse(text), "#", 0)
  let before = string.drop_end(text, hashes)
  case hashes > 0 && { before == "" || string.ends_with(before, " ") } {
    True -> string.trim_end(before)
    False -> text
  }
}

/// The anchor that GitHub gives a heading with this text (one heading,
/// with no `-1` for a repeated anchor; see `heading_anchors`).
///
/// The rule:
///
/// 1. Remove the spaces at the start and the end of the heading text.
/// 2. Remove the Markdown and HTML marks. Inline HTML tags, such as a badge
///    link, are removed, and the text between them is kept. The spaces
///    around a tag stay. A link `[text](address)` keeps its text. Backticks
///    are removed, and the text of a code span is kept as it is. A `_` at
///    the start or end of a word outside a code span is an emphasis mark,
///    and is removed.
/// 3. Change the text to lowercase.
/// 4. Remove each character that is not a letter, a digit, a space, a
///    hyphen or an underscore. Letters and digits of every script are kept,
///    and so are combining marks.
/// 5. Change each space to a hyphen. The spaces are not trimmed after the
///    tags are removed, so each space before a badge link at the end of a
///    heading gives a hyphen at the end of the anchor.
///
/// For example, ``The `RequestBody` type`` gives `the-requestbody-type`,
/// `What's New` gives `whats-new` and `HTTP/2 over TLS` gives
/// `http2-over-tls`. `Check one document <a href="..."><img ...></a>`
/// gives `check-one-document-`, and a heading with two badge links after
/// its text, each after a space, gets two hyphens at the end.
pub fn heading_slug(heading: String) -> String {
  heading
  |> string.trim
  |> string.split("`")
  |> list.index_map(fn(part, index) {
    case index % 2 {
      0 -> remove_inline_marks(part)
      _ -> part
    }
  })
  |> string.join("")
  |> string.lowercase
  |> keep_slug_characters
  |> string.replace(" ", "-")
}

@external(erlang, "dream_snippets_ffi", "keep_slug_characters")
fn keep_slug_characters(text: String) -> String

fn remove_inline_marks(text: String) -> String {
  text
  |> remove_html_tags
  |> keep_link_text
  |> string.split(" ")
  |> list.map(remove_emphasis_underscores)
  |> string.join(" ")
}

/// Removes each `<tag ...>` and `</tag>`. A `<` that does not start a tag,
/// as in `a < b`, is kept.
fn remove_html_tags(text: String) -> String {
  string.split(text, "<")
  |> map_after_first(after_tag)
  |> string.join("")
}

/// Changes each item of a list but the first one.
fn map_after_first(items: List(String), change: fn(String) -> String) {
  list.index_map(items, fn(item, index) {
    case index {
      0 -> item
      _ -> change(item)
    }
  })
}

fn after_tag(part: String) -> String {
  let is_tag =
    starts_with_one_of(part, lowercase_letters <> uppercase_letters <> "/")
  case is_tag, string.split_once(part, ">") {
    True, Ok(#(_tag, after)) -> after
    _, _ -> "<" <> part
  }
}

/// Changes each `[text](address)` to `[text`. The `[` is removed later with
/// the other marks.
fn keep_link_text(text: String) -> String {
  string.split(text, "](")
  |> map_after_first(after_address)
  |> string.join("")
}

fn after_address(part: String) -> String {
  case string.split_once(part, ")") {
    Ok(#(_address, after)) -> after
    Error(Nil) -> "](" <> part
  }
}

fn remove_emphasis_underscores(word: String) -> String {
  let leading = count_leading(word, "_", 0)
  let without_leading = string.drop_start(word, leading)
  let trailing = count_leading(string.reverse(without_leading), "_", 0)
  string.drop_end(without_leading, trailing)
}

// ---------------------------------------------------------------------------
// Diff blocks
// ---------------------------------------------------------------------------

/// Checks a diff block: its heading and diff badge, the compare link, and
/// that its lines are in the real git diff of the file it names.
fn check_diff_block(
  block: FencedBlock,
  above: List(Line),
  file: String,
  context: CheckContext,
) -> List(Problem) {
  case first_line_skipping_one_blank(above) {
    None -> [
      Problem(file:, line: block.opening_line, reason: MissingDiffBadgeHeading),
    ]
    Some(heading) -> diff_heading_problems(heading, block, file, context)
  }
}

fn diff_heading_problems(
  heading: Line,
  block: FencedBlock,
  file: String,
  context: CheckContext,
) -> List(Problem) {
  let link =
    parse_diff_badge_heading(heading.text)
    |> result.try(parse_compare_link(_, context.project.repository))
  case link {
    Ok(link) ->
      check_compare_link(link, block, context)
      |> list.map(fn(found) { Problem(file:, line: found.0, reason: found.1) })
    Error(reason) -> [Problem(file:, line: block.opening_line, reason:)]
  }
}

/// Reads a diff badge link address into a compare link. The address must
/// be `https://github.com/<owner>/<name>/compare/<old>...<new>#diff-<hex>`
/// for `repository`, and both tags must be safe tag names (see
/// `is_safe_tag`).
///
/// ## Errors
///
/// `NotCompareLink(address)` when the address has another form.
pub fn parse_compare_link(
  address: String,
  repository: GitHubRepository,
) -> Result(CompareLink, Reason) {
  let not_compare_link = NotCompareLink(address)
  use after_prefix <- result.try(
    remove_prefix(address, repository_url(repository) <> "/compare/")
    |> result.replace_error(not_compare_link),
  )
  use #(range, anchor) <- result.try(
    string.split_once(after_prefix, "#")
    |> result.replace_error(not_compare_link),
  )
  use #(old_tag, new_tag) <- result.try(
    string.split_once(range, "...")
    |> result.replace_error(not_compare_link),
  )
  use anchor_digest <- result.try(
    remove_prefix(anchor, diff_anchor_prefix)
    |> result.replace_error(not_compare_link),
  )
  case is_safe_tag(old_tag) && is_safe_tag(new_tag) && anchor_digest != "" {
    True -> Ok(CompareLink(old_tag:, new_tag:, anchor_digest:))
    False -> Error(not_compare_link)
  }
}

/// Tells whether a text is a safe tag name to give to git: letters, digits,
/// `.`, `_` and `-`, not starting with `-` and with no `..`.
pub fn is_safe_tag(tag: String) -> Bool {
  tag != ""
  && is_made_of(tag, tag_characters)
  && !string.starts_with(tag, "-")
  && !string.contains(tag, "..")
}

/// Tells whether a text is a safe repository path to give to git: a path
/// inside the repository (see `is_repository_path`) made of letters,
/// digits, `.`, `_`, `-` and `/`, not starting with `-`.
pub fn is_safe_path(path: String) -> Bool {
  is_repository_path(path)
  && is_made_of(path, path_characters)
  && !string.starts_with(path, "-")
}

const tag_characters =
  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-"

const path_characters =
  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-/"

fn is_made_of(text: String, characters: String) -> Bool {
  text
  |> string.to_graphemes
  |> list.all(fn(character) { string.contains(characters, character) })
}

/// Checks a compare link against its block. The new tag is checked on its
/// own. The file header, the anchor, the old tag, the diff and the lines
/// are checked in order, each only when the one before it passed. Each
/// problem comes with the line of the document that it is about.
fn check_compare_link(
  link: CompareLink,
  block: FencedBlock,
  context: CheckContext,
) -> List(#(Int, Reason)) {
  let release_tag = context.project.version
  let tag_problems = case link.new_tag == release_tag {
    True -> []
    False -> [
      #(
        block.opening_line,
        WrongNewTag(found: link.new_tag, expected: release_tag),
      ),
    ]
  }
  let content_problems = case check_diff_content(link, block, context) {
    Ok(Nil) -> []
    Error(problem) -> [problem]
  }
  list.append(tag_problems, content_problems)
}

fn check_diff_content(
  link: CompareLink,
  block: FencedBlock,
  context: CheckContext,
) -> Result(Nil, #(Int, Reason)) {
  let at_block = fn(reason) { #(block.opening_line, reason) }
  use #(path, body) <- result.try(
    parse_diff_file_header(block.content) |> result.map_error(at_block),
  )
  use Nil <- result.try(
    check_diff_anchor(link, path) |> result.map_error(at_block),
  )
  use Nil <- result.try(
    require_old_tag(link.old_tag, context) |> result.map_error(at_block),
  )
  use diff_text <- result.try(
    context.diff_from_tag(link.old_tag, path)
    |> result.map_error(fn(error) { at_block(GitUnavailable(error)) }),
  )
  case parse_hunks(diff_text) {
    [] -> Error(at_block(NoDiffForPath(path:, old_tag: link.old_tag)))
    hunks -> {
      let line_not_found = DiffLineNotFound(path:, old_tag: link.old_tag)
      match_segments(diff_segments(body), hunks, line_not_found)
    }
  }
}

/// Reads the `--- a/<path>` and `+++ b/<path>` lines at the start of a diff
/// block, and returns the path and the lines after them.
fn parse_diff_file_header(
  content: List(Line),
) -> Result(#(String, List(Line)), Reason) {
  case content {
    [old_file, new_file, ..body] ->
      diff_file_path(old_file.text, new_file.text)
      |> result.try(fn(path) { require_diff_body(path, body) })
    _ -> Error(MissingDiffFileHeader)
  }
}

fn diff_file_path(
  old_file: String,
  new_file: String,
) -> Result(String, Reason) {
  let old_path = remove_prefix(old_file, "--- a/")
  let new_path = remove_prefix(new_file, "+++ b/")
  case old_path, new_path {
    Ok(old_path), Ok(new_path) if old_path == new_path ->
      safe_path_or_error(old_path)
    _, _ -> Error(MissingDiffFileHeader)
  }
}

fn safe_path_or_error(path: String) -> Result(String, Reason) {
  case is_safe_path(path) {
    True -> Ok(path)
    False -> Error(MissingDiffFileHeader)
  }
}

fn require_diff_body(
  path: String,
  body: List(Line),
) -> Result(#(String, List(Line)), Reason) {
  case body {
    [] -> Error(EmptyDiffBlock)
    _ -> Ok(#(path, body))
  }
}

/// The SHA-256 hex digest of a repository path. GitHub's compare view
/// gives each file the anchor `#diff-` followed by this digest.
pub fn path_digest(path: String) -> String {
  sha256_hex(path)
}

@external(erlang, "dream_snippets_ffi", "sha256_hex")
fn sha256_hex(text: String) -> String

fn check_diff_anchor(link: CompareLink, path: String) -> Result(Nil, Reason) {
  let digest = path_digest(path)
  case link.anchor_digest == digest {
    True -> Ok(Nil)
    False ->
      Error(WrongDiffAnchor(
        path:,
        expected: "#" <> diff_anchor_prefix <> digest,
      ))
  }
}

fn require_old_tag(tag: String, context: CheckContext) -> Result(Nil, Reason) {
  case context.tag_exists(tag) {
    Ok(True) -> Ok(Nil)
    Ok(False) -> Error(MissingOldTag(tag))
    Error(error) -> Error(GitUnavailable(error))
  }
}

/// Splits the text of a git diff into its hunks. The lines before the first
/// `@@` header (`diff --git`, `index`, `---` and `+++`) are left out.
pub fn parse_hunks(diff_text: String) -> List(DiffHunk) {
  source_lines(diff_text)
  |> list.fold([], add_to_hunks)
  |> list.reverse
  |> list.map(fn(hunk) { DiffHunk(..hunk, lines: list.reverse(hunk.lines)) })
}

/// Adds one line of a diff to the hunks, which are held last first, each
/// with its lines last first.
fn add_to_hunks(hunks: List(DiffHunk), text: String) -> List(DiffHunk) {
  case is_hunk_header(text), hunks {
    True, _ -> [DiffHunk(header: text, lines: []), ..hunks]
    False, [] -> []
    False, [current, ..rest] -> [
      DiffHunk(..current, lines: [text, ..current.lines]),
      ..rest
    ]
  }
}

fn is_hunk_header(text: String) -> Bool {
  string.starts_with(text, "@@")
}

/// Splits the lines of a diff block, after its file header, at each `@@`
/// header. Only the first segment can have no header, and it is left out
/// when it is empty.
fn diff_segments(body: List(Line)) -> List(DiffSegment) {
  body
  |> list.fold([], add_to_segments)
  |> list.reverse
  |> list.map(fn(segment) {
    DiffSegment(..segment, lines: list.reverse(segment.lines))
  })
}

fn add_to_segments(
  segments: List(DiffSegment),
  line: Line,
) -> List(DiffSegment) {
  case is_hunk_header(line.text), segments {
    True, _ -> [
      DiffSegment(
        header: Some(line),
        first_line_number: line.number + 1,
        lines: [],
      ),
      ..segments
    ]
    False, [] -> [
      DiffSegment(header: None, first_line_number: line.number, lines: [line]),
    ]
    False, [current, ..rest] -> [
      DiffSegment(..current, lines: [line, ..current.lines]),
      ..rest
    ]
  }
}

/// Finds each segment of a block in the hunks of the real diff, in order.
/// A segment with a header must be in the first later hunk with the same
/// header. A segment with no header can be in any hunk. Its lines must be
/// contiguous within that one hunk. The next segment is looked for in the
/// hunks after it.
fn match_segments(
  segments: List(DiffSegment),
  hunks: List(DiffHunk),
  line_not_found: Reason,
) -> Result(Nil, #(Int, Reason)) {
  case segments {
    [] -> Ok(Nil)
    [segment, ..rest] -> {
      use hunks_after <- result.try(match_segment(
        segment,
        hunks,
        line_not_found,
      ))
      match_segments(rest, hunks_after, line_not_found)
    }
  }
}

fn match_segment(
  segment: DiffSegment,
  hunks: List(DiffHunk),
  line_not_found: Reason,
) -> Result(List(DiffHunk), #(Int, Reason)) {
  let texts = list.map(segment.lines, fn(line) { line.text })
  case segment.header {
    None ->
      find_lines(texts, hunks, 0)
      |> result.map_error(fn(index) {
        #(line_number_at(segment, index), line_not_found)
      })
    Some(header) ->
      match_headed_segment(header, texts, hunks)
      |> result.map_error(fn(missing) {
        headed_segment_problem(segment, header, missing, line_not_found)
      })
  }
}

fn headed_segment_problem(
  segment: DiffSegment,
  header: Line,
  missing: Option(Int),
  line_not_found: Reason,
) -> #(Int, Reason) {
  case missing {
    Some(index) -> #(line_number_at(segment, index), line_not_found)
    None -> #(header.number, HunkHeaderNotFound(header.text))
  }
}

/// Finds the first hunk with the header, and the lines in it. The error is
/// `None` when no hunk has the header, or the index of the first line that
/// is not in the hunk.
fn match_headed_segment(
  header: Line,
  texts: List(String),
  hunks: List(DiffHunk),
) -> Result(List(DiffHunk), Option(Int)) {
  let from_header =
    list.drop_while(hunks, fn(hunk) {
      !header_matches(header.text, hunk.header)
    })
  case from_header {
    [] -> Error(None)
    [hunk, ..after] ->
      find_lines(texts, [hunk], 0)
      |> result.replace(after)
      |> result.map_error(Some)
  }
}

/// A block header matches a real one when it is the same line, or the
/// same `@@ -a,b +c,d @@` part without the function name that git adds.
fn header_matches(block_header: String, real_header: String) -> Bool {
  block_header == real_header || block_header == header_ranges(real_header)
}

fn header_ranges(header: String) -> String {
  case string.split_once(string.drop_start(header, 2), "@@") {
    Ok(#(ranges, _function_name)) -> "@@" <> ranges <> "@@"
    Error(Nil) -> header
  }
}

/// Finds the lines as a contiguous run in one of the hunks, and returns
/// the hunks after that one. When no hunk holds all of them, the error is
/// the index of the first line after the longest run that was found.
fn find_lines(
  texts: List(String),
  hunks: List(DiffHunk),
  best: Int,
) -> Result(List(DiffHunk), Int) {
  case hunks {
    [] -> Error(best)
    [hunk, ..rest] -> {
      let matched = longest_run(texts, hunk.lines, 0)
      case matched == list.length(texts) {
        True -> Ok(rest)
        False -> find_lines(texts, rest, int.max(best, matched))
      }
    }
  }
}

/// The largest number of leading `needle` lines found in a row anywhere in
/// `haystack`.
fn longest_run(needle: List(String), haystack: List(String), best: Int) -> Int {
  case haystack {
    [] -> best
    [_, ..rest] ->
      longest_run(
        needle,
        rest,
        int.max(best, common_prefix_length(needle, haystack, 0)),
      )
  }
}

fn common_prefix_length(
  first: List(String),
  second: List(String),
  count: Int,
) -> Int {
  case first, second {
    [first_line, ..first_rest], [second_line, ..second_rest]
      if first_line == second_line
    -> common_prefix_length(first_rest, second_rest, count + 1)
    _, _ -> count
  }
}

fn line_number_at(segment: DiffSegment, index: Int) -> Int {
  segment.first_line_number + index
}

// ---------------------------------------------------------------------------
// Gleam code outside gleam fences
// ---------------------------------------------------------------------------

/// Tells whether a line looks like Gleam code.
///
/// It matches only forms that the other languages in the docs (shell,
/// TOML, YAML, JavaScript, TypeScript, SQL, Elixir, Gherkin, Markdown,
/// Dockerfile, diagrams) do not have, so that their fences pass:
///
/// - `import a/b` or `import a.{...}`. JavaScript imports use quotes and
///   `from`, and Python imports have no `/` and no `.{`.
/// - `fn name(` or `pub fn name(`. Elixir writes `fn x ->` and `fn(`,
///   JavaScript writes `function`.
/// - `pub type Name`, `pub opaque type Name`, or `type Name` with no `=`.
///   TypeScript type aliases always have `=`.
/// - `use name <- ...`. Rust `use` lines have no `<-`.
/// - `let assert ...`.
/// - `|> module.function(`, a pipe into a lowercase module. Elixir and F#
///   pipes call capitalised modules (`|> Enum.map(`).
///
/// Rust also has `fn name(`; the docs have no Rust code.
pub fn looks_like_gleam(text: String) -> Bool {
  let code = string.trim_start(text)
  is_gleam_import(code)
  || is_gleam_function(code)
  || is_gleam_type(code)
  || is_gleam_use(code)
  || string.starts_with(code, "let assert ")
  || has_gleam_pipe(code)
}

fn is_gleam_import(code: String) -> Bool {
  case code {
    "import " <> rest -> {
      let #(module, after) = take_while_in(rest, module_path_characters, "")
      starts_with_lowercase(module)
      && { string.contains(module, "/") || string.starts_with(after, ".{") }
    }
    _ -> False
  }
}

fn is_gleam_function(code: String) -> Bool {
  case code {
    "pub fn " <> rest | "fn " <> rest -> {
      let #(name, after) = take_while_in(rest, name_characters, "")
      starts_with_lowercase(name) && string.starts_with(after, "(")
    }
    _ -> False
  }
}

fn is_gleam_type(code: String) -> Bool {
  case code {
    "pub type " <> rest | "pub opaque type " <> rest | "type " <> rest ->
      starts_with_uppercase(rest) && !string.contains(rest, "=")
    _ -> False
  }
}

fn is_gleam_use(code: String) -> Bool {
  string.starts_with(code, "use ") && string.contains(code, " <- ")
}

fn has_gleam_pipe(code: String) -> Bool {
  string.split(code, "|> ")
  |> list.drop(1)
  |> list.any(is_module_call)
}

fn is_module_call(code: String) -> Bool {
  let #(module, after_module) = take_while_in(code, name_characters, "")
  let #(function, after_function) =
    take_while_in(string.drop_start(after_module, 1), name_characters, "")
  starts_with_lowercase(module)
  && string.starts_with(after_module, ".")
  && starts_with_lowercase(function)
  && string.starts_with(after_function, "(")
}

const lowercase_letters = "abcdefghijklmnopqrstuvwxyz"

const uppercase_letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

const name_characters = "abcdefghijklmnopqrstuvwxyz0123456789_"

const module_path_characters = "abcdefghijklmnopqrstuvwxyz0123456789_/"

fn take_while_in(
  text: String,
  characters: String,
  taken: String,
) -> #(String, String) {
  case string.pop_grapheme(text) {
    Ok(#(first, rest)) -> take_if_in(first, rest, text, characters, taken)
    Error(Nil) -> #(taken, text)
  }
}

fn take_if_in(
  first: String,
  rest: String,
  text: String,
  characters: String,
  taken: String,
) -> #(String, String) {
  case string.contains(characters, first) {
    True -> take_while_in(rest, characters, taken <> first)
    False -> #(taken, text)
  }
}

fn starts_with_lowercase(text: String) -> Bool {
  starts_with_one_of(text, lowercase_letters)
}

fn starts_with_uppercase(text: String) -> Bool {
  starts_with_one_of(text, uppercase_letters)
}

fn starts_with_one_of(text: String, characters: String) -> Bool {
  case string.pop_grapheme(text) {
    Ok(#(first, _)) -> string.contains(characters, first)
    Error(Nil) -> False
  }
}

fn option_to_list(value: Option(a)) -> List(a) {
  case value {
    Some(item) -> [item]
    None -> []
  }
}
