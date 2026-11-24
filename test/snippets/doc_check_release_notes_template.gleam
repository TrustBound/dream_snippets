//// Doc comment: check.check_release_notes_template
////
//// Checks release notes that have no Community section.

import dream_snippets/check.{type Problem}

pub fn check_my_release_notes() -> List(Problem) {
  let release_notes =
    "# My App 1.2.0 Release Notes

**Release Date:** 2026-11-20

## Key Highlights

## What's New

## Testing

## Installing

## Documentation
"
  // Returns [
  //   Problem(
  //     file: "releases/release-1.2.0.md",
  //     line: 1,
  //     reason: MissingReleaseNotesSection("Community"),
  //   ),
  // ]
  check.check_release_notes_template("releases/release-1.2.0.md", release_notes)
}
