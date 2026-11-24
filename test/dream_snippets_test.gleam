import dream_snippets/block_kinds_test
import dream_snippets/check_test
import dream_snippets/config_test
import dream_snippets/git_test
import dream_snippets/guide_badge_test
import dream_snippets/guide_fixing_check_failures_test
import dream_snippets/guide_getting_started_test
import dream_snippets/guide_reference_test
import dream_snippets/guide_release_notes_template_test
import dream_snippets/guide_tested_code_blocks_test
import dream_snippets/guide_upgrade_guides_test
import dream_snippets/guide_use_from_gleam_test
import dream_snippets/old_code_test
import dream_snippets/project_test
import dream_snippets/release_code_test
import dream_snippets/release_history_test
import dream_snippets/release_notes_template_test
import dream_test/coverage
import dream_test/reporters/bdd
import dream_test/reporters/progress
import dream_test/runner
import snippets_test

pub fn main() {
  runner.new([
    block_kinds_test.tests(),
    check_test.tests(),
    config_test.tests(),
    git_test.tests(),
    guide_badge_test.tests(),
    guide_fixing_check_failures_test.tests(),
    guide_getting_started_test.tests(),
    guide_reference_test.tests(),
    guide_release_notes_template_test.tests(),
    guide_tested_code_blocks_test.tests(),
    guide_upgrade_guides_test.tests(),
    guide_use_from_gleam_test.tests(),
    old_code_test.tests(),
    project_test.tests(),
    release_code_test.tests(),
    release_history_test.tests(),
    release_notes_template_test.tests(),
    snippets_test.tests(),
  ])
  |> runner.progress_reporter(progress.new())
  |> runner.results_reporters([bdd.new() |> bdd.color()])
  |> runner.coverage(
    coverage.new()
    |> coverage.show_missing()
    |> coverage.minimum_percent(100.0)
    |> coverage.json_path("build/coverage/coverage.json"),
  )
  |> runner.exit_on_failure()
  |> runner.run()
}
