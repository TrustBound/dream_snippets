//// Guide: Getting started, step 2
////
//// The code that the guide of the example project shows.

import gleam/string

pub fn greeting(name: String) -> String {
  "Hello, " <> string.capitalise(name) <> "!"
}
