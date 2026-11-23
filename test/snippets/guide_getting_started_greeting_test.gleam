//// Guide: Getting started, step 2
////
//// The test that runs the snippet, in the form gleeunit runs.

import snippets/guide_getting_started_greeting

pub fn greeting_test() {
  let assert "Hello, Lucy!" = guide_getting_started_greeting.greeting("lucy")
}
