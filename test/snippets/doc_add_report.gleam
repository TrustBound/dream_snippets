//// Doc comment: check.add_report
////
//// Adds two reports.

import dream_snippets/check.{type Report}

pub fn two_reports() -> Report {
  let first = check.Report(..check.empty_report(), blocks_checked: 2)
  let second = check.Report(..check.empty_report(), output_blocks_checked: 1)
  // Returns Report(blocks_checked: 2, diff_blocks_checked: 0,
  //   file_blocks_checked: 0, command_blocks_checked: 0,
  //   output_blocks_checked: 1, illustration_blocks: 0, problems: [])
  check.add_report(first, second)
}
