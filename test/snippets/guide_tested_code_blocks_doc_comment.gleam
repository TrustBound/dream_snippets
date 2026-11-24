//// Guide: Tested code blocks, step 3
////
//// A function whose doc comment shows a tested example.

import gleam/string

/// Builds a greeting for a name.
///
/// ## Examples
///
/// ### Greet Lucy <a href="https://github.com/me/my_app/blob/0.1.0/test/snippets/guide_tested_code_blocks_greet_lucy.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import snippets/guide_tested_code_blocks_doc_comment as greeting
///
/// pub fn greet_lucy() -> String {
///   // Returns "Hello, Lucy!"
///   greeting.greeting("lucy")
/// }
/// ```
pub fn greeting(name: String) -> String {
  "Hello, " <> string.capitalise(name) <> "!"
}
