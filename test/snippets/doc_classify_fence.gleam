//// Doc comment: check.classify_fence
////
//// Reads the kind of each fence from its info string.

import dream_snippets/check.{type BlockKind}
import gleam/list

pub fn fence_kinds() -> List(BlockKind) {
  // Returns [GleamBlock, CommandBlock("sh"), OutputBlock,
  //   IllustrationBlock("text"), FileBlock("yaml"), UnlabelledBlock]
  list.map(
    ["gleam", "sh", "text", "text illustration", "yaml", ""],
    check.classify_fence,
  )
}
