//// Doc comment: check.one_line
////
//// Shows a line break in a message in a visible form.

import dream_snippets/check

pub fn visible_line_break() -> String {
  // Returns "found \\n where \" was expected", with a backslash and an n in
  // place of the line break
  check.one_line("found \n where \" was expected")
}
