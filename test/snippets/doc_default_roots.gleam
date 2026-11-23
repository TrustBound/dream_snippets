//// Doc comment: config.default_roots
////
//// Lists the paths that the check reads when gleam.toml sets none.

import dream_snippets/config
import gleam/list

pub fn default_paths() -> List(String) {
  // Returns [
  //   "README.md", "SECURITY.md", "docs", "examples", "CHANGELOG.md",
  //   "releases", "src",
  // ]
  list.map(config.default_roots(), fn(root) { root.path })
}
