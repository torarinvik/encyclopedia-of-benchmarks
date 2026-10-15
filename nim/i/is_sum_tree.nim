const MaxNodes = 400
const InvalidResult = -9_000_000_000_000_000_000'i64

proc subtreeSum(nodes: ptr UncheckedArray[int64], index: int64): int64 =
  if index < 0: return 0
  let base = int(index) * 3
  nodes[base] + subtreeSum(nodes, nodes[base + 1]) + subtreeSum(nodes, nodes[base + 2])

proc checkNode(nodes: ptr UncheckedArray[int64], index: int64): bool =
  let base = int(index) * 3
  let value = nodes[base]; let left = nodes[base + 1]; let right = nodes[base + 2]
  if left == -1 and right == -1: return true
  let leftSum = subtreeSum(nodes, left); let rightSum = subtreeSum(nodes, right)
  let leftOk = if left == -1: true else: checkNode(nodes, left)
  let rightOk = if right == -1: true else: checkNode(nodes, right)
  value == leftSum + rightSum and leftOk and rightOk

proc is_sum_tree*(nodes: ptr UncheckedArray[int64], count: csize_t, root: int64): int64
    {.cdecl, exportc: "is_sum_tree".} =
  if nodes == nil or count == 0 or count > MaxNodes or root < 0 or root >= int64(count): return InvalidResult
  var seen: array[MaxNodes, bool]
  var stack: array[MaxNodes * 2, int64]
  var top = 0
  stack[top] = root; inc top
  while top > 0:
    dec top
    let index = stack[top]
    if index < 0 or index >= int64(count) or seen[int(index)]: return InvalidResult
    seen[int(index)] = true
    let base = int(index) * 3
    let value = nodes[base]; let left = nodes[base + 1]; let right = nodes[base + 2]
    if value < -1_000_000_000 or value > 1_000_000_000 or left < -1 or right < -1 or
        (left >= 0 and left >= int64(count)) or (right >= 0 and right >= int64(count)): return InvalidResult
    if left >= 0: stack[top] = left; inc top
    if right >= 0: stack[top] = right; inc top
  if checkNode(nodes, root): 1 else: 0
