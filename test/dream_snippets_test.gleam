import dream_snippets/check_test
import dream_snippets/config_test
import dream_snippets/git_test
import dream_snippets/guide_badge_test
import dream_snippets/project_test
import dream_snippets/release_notes_template_test
import dream_test/coverage
import dream_test/reporters/bdd
import dream_test/reporters/progress
import dream_test/runner
import snippets_test

pub fn main() {
  runner.new([
    check_test.tests(),
    config_test.tests(),
    git_test.tests(),
    guide_badge_test.tests(),
    project_test.tests(),
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
