const MissingNode = -2_147_483_649'i64
const MaxSlots = 255

proc binary_tree_is_sorted_local*(nodes: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "binary_tree_is_sorted_local".} =
  if length == 0 or length > csize_t(MaxSlots) or nodes.isNil or nodes[0] == MissingNode: return -1
  for index in 0 ..< int(length):
    let value = nodes[index]
    if value == MissingNode: continue
    if value < -2_147_483_648'i64 or value > 2_147_483_647'i64: return -1
    if index > 0:
      let parent = (index - 1) div 2
      if nodes[parent] == MissingNode: return -1
      if (index mod 2 == 1 and value > nodes[parent]) or
         (index mod 2 == 0 and value < nodes[parent]): return 0
  1
