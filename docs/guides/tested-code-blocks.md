# Tested code blocks

This guide shows the exact heading and badge forms that the check wants. Copy a heading from here when a message says that a badge is not in the exact format.

## Write a tested code block

1. Write the code in `test/snippets/<name>.gleam`.
2. Run it from a test, so that the tests fail when the snippet breaks.
3. Copy the code into the doc.
4. Put a heading directly above the code block, with a "tested snippet" badge at its end. The badge links to the snippet file in your GitHub repository, at the tag of the `version` in `gleam.toml`.

```markdown
### Encode a user <a href="https://github.com/me/my_app/blob/1.2.0/test/snippets/encode_user.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
```

One blank line between the heading and the block is allowed. Use the full GitHub URL, because HexDocs and Hex show the docs without the repository.

For an excerpt, end the link with a GitHub line range, for example `#L8-L10`. The block then shows those lines, with the same indent. A whole-file block can leave out the `////` module comment at the top of the file and the blank line after it.

Examples in doc comments are code blocks too. Put the heading and the badge inside the comment, directly above the example.

## Add the guide badge to a README example

Each example in the root `README.md` of a project has a second badge, the guide badge. It links to the section of a guide that explains the example. The guide badge comes after the tested snippet badge, with one space between them. Both images float right, so the guide badge shows to the left of the tested snippet badge:

```markdown
### Encode a user <a href="https://github.com/me/my_app/blob/1.2.0/test/snippets/encode_user.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a> <a href="https://github.com/me/my_app/blob/1.2.0/docs/guides/encoding.md#encode-a-user"><img align="right" alt="Guide" src="https://img.shields.io/badge/%F0%9F%93%96_read-guide-blue.svg?style=flat-square"></a>
```

The check wants these things of the guide badge:

- The link is a `blob` link of the same repository, at the tag of the `version` in `gleam.toml`.
- The path is a `.md` file under a guide directory. The default directory is `docs/guides`. The `guides` setting changes it.
- The guide file exists.
- The link ends with `#<anchor>`, and the anchor is the anchor of a heading in the guide.
- The guide has a tested snippet badge that links to the same snippet file. The line range can be different.

The guide badge is only for the root README. A heading in a guide, the changelog, release notes or a doc comment has only the tested snippet badge. A `diff` block heading has no guide badge.

### Heading anchors

The anchor of a heading is the one that GitHub makes:

1. Remove inline HTML tags, such as a badge link, and Markdown marks. A link keeps its text, and a code span keeps its text.
2. Remove the spaces at the start and the end.
3. Change the text to lowercase.
4. Remove each character that is not a letter, a digit, a space, a hyphen or an underscore.
5. Change each space to a hyphen.

For example, `What's New` gets `whats-new`, and ``The `RequestBody` type`` gets `the-requestbody-type`. When two headings get the same anchor, the second one gets `-1` at the end, and the third one gets `-2`.

## Show a change with a diff block

Old code does not compile on the new version. Thus an upgrade guide shows each change as a `diff` block: an excerpt of the real git diff of one file, from the last release tag to the working tree. The block starts with the `--- a/<path>` and `+++ b/<path>` lines. Lines with no `@@` hunk header between them must come from one hunk, in order.

The heading ends with a "tested diff" badge that links to the file in GitHub's compare view. The anchor is `#diff-` and the SHA-256 hex digest of the path (`printf '%s' <path> | shasum -a 256`):

```markdown
#### Read a stream from `request.body` <a href="https://github.com/me/my_app/compare/1.1.0...1.2.0#diff-96161bd1d29b10b5817d71e3db6be67d9a8494e6ea36bc113379cb3b2743ce32"><img align="right" alt="Tested diff" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-diff-lightgreen.svg?style=flat-square"></a>
```

The check runs `git diff <old tag> -- <path>`, so it needs the release tags in the clone. A shallow clone in CI has none. Check out with `fetch-depth: 0`.

## What the check finds

The check fails when:

- a Gleam code block has no heading with the badge directly above it
- the badge is not in the exact format shown above
- the badge links to another repository or host
- the tag in the link is not the `version` in `gleam.toml`
- the linked file does not exist, or cannot be read
- the line range is malformed, reversed, or past the end of the file
- the code block is not the same as the linked file or line range
- the code block uses the old `🧪 Tested source` line
- a README example has no guide badge, or the guide badge is not in the exact format or place
- the guide badge link is not a link of the repository at the release tag, is not a `.md` file under a guide directory, or has no anchor
- the guide file does not exist, has no heading with the anchor, or does not link to the snippet of the example
- a heading outside the README has a guide badge
- a code fence with another language, or with no language, holds Gleam code
- a code fence has no closing fence
- a `diff` block has no heading with the tested diff badge, or the badge is not in the exact format
- the diff badge link is not a compare link of the repository, its new tag is not the `version` in `gleam.toml`, or its anchor is not the digest of the path in the block
- the old tag is not in the clone
- the file has no diff between the old tag and the working tree, or a line of the block is not in that diff at that place

A ```` ```markdown ```` fence holds an example document. The check examines its fences too, and its other lines must not look like Gleam code.

The [Release notes template](https://github.com/TrustBound/dream_snippets/blob/main/docs/guides/release-notes-template.md) guide shows the checks of release notes.
