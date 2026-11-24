//// Doc comment: check.repository_url
////
//// Gives the address of a GitHub repository.

import dream_snippets/check.{GitHubRepository}

pub fn dream_url() -> String {
  // Returns "https://github.com/TrustBound/dream"
  check.repository_url(GitHubRepository(owner: "TrustBound", name: "dream"))
}
