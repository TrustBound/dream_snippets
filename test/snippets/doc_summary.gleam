//// Doc comment: check.summary
////
//// Writes the last line of the output.

import dream_snippets/check

pub fn summary_line() -> String {
  let report =
    check.Report(
      ..check.empty_report(),
      blocks_checked: 12,
      diff_blocks_checked: 2,
      command_blocks_checked: 1,
      output_blocks_checked: 4,
      problems: [check.Problem("README.md", 3, check.UnlabelledFence)],
    )
  // Returns "12 blocks and 2 diff blocks checked in 9 files, 1 problem; 0 file blocks, 1 command block and 4 output blocks checked; 0 illustration blocks"
  check.summary(report, 9)
}
