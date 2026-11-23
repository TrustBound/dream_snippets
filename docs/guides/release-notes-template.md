# Release notes template

All release notes of the Dream repositories follow one template. This guide shows the template, and the check enforces it.

## The template

The check reads each release notes file of `checked_from_version` and later. It reads headings outside code fences only, and it ignores HTML after a heading, such as a badge.

1. The first line is `# <Name> <version> Release Notes`. `<version>` is the version in the file name, so `releases/release-3.0.0.md` has `3.0.0`. `<Name>` is any text, for example `Dream`, `dream_json` or `Dream Test`.
2. A line that starts with `**Release Date:**` comes after the title and before the first `##` section.
3. The `##` sections are only these, each one time at most, in this order:
   1. `Key Highlights` (required)
   2. `What's New` (required)
   3. `Deprecated`
   4. `Removed`
   5. `Bug Fixes`
   6. `Known Limits`
   7. `Testing` (required)
   8. `Upgrading` or `Installing` (exactly one of the two is required, and `Installing` is for a first release)
   9. `Acknowledgements`
   10. `Documentation` (required)
   11. `Community` (required)
4. The `Upgrading` section has a `### Migration Guide` heading.

## The smallest release notes

```markdown
# my_app 1.2.0 Release Notes

**Release Date:** 2026-11-20

## Key Highlights

## What's New

## Testing

## Upgrading

### Migration Guide

## Documentation

## Community
```

## Messages

Each template message ends with a pointer to this guide, for example:

```text
releases/release-1.2.0.md:1: the section "## Testing" is missing, but the template requires it; see "Release notes template" in https://hexdocs.pm/dream_snippets/guides/release-notes-template.html
```

A project sets `release_notes_guide` to point at its own page. The [Configuration](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/configuration.md) guide shows the setting.

The check fails when:

- the first line of release notes is not `# <Name> <version> Release Notes`, with the version in the file name
- release notes have no `**Release Date:**` line between the title and the first section
- release notes have a `##` section that is not in the template, that comes after a section that the template has after it, or that is in the file two times
- release notes do not have a required section, or have both `## Upgrading` and `## Installing`
- the `## Upgrading` section has no `### Migration Guide`
