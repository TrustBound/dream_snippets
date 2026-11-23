//// Guide: Use it from Gleam, step 5
////
//// Builds the CheckContext of a real project, as the command does.

import dream_snippets/check.{type CheckContext, CheckContext}
import dream_snippets/config.{type Config}
import dream_snippets/git.{Git}
import simplifile

pub fn context_for(directory: String, configuration: Config) -> CheckContext {
  let repository = Git(program: "git", directory:)
  CheckContext(
    project: configuration.project,
    checked_from_version: configuration.checked_from_version,
    read_source: fn(path) { simplifile.read(directory <> "/" <> path) },
    tag_exists: fn(tag) { git.tag_exists(repository, tag) },
    diff_from_tag: fn(tag, path) { git.diff_from_tag(repository, tag, path) },
    diff_between_tags: fn(old_tag, new_tag, path) {
      git.diff_between_tags(repository, old_tag, new_tag, path)
    },
    file_at_tag: fn(tag, path) { git.file_at_tag(repository, tag, path) },
  )
}
