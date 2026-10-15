## Trim a strict BST and serialize the retained tree in preorder node-table order.
const MaxNodeCount = 100
const MaxValue = 10000'i64

proc validBst(nodes: ptr UncheckedArray[int64], nodeCount: int, rootIndex: int): bool =
  var parents: array[MaxNodeCount, int]
  for index in 0 ..< nodeCount:
    let value = nodes[3 * index]
    let left = nodes[3 * index + 1]
    let right = nodes[3 * index + 2]
    if value < 1 or value > MaxValue or left < -1 or right < -1 or
        (left >= 0 and left >= int64(nodeCount)) or (right >= 0 and right >= int64(nodeCount)):
      return false
    if left >= 0:
      inc parents[int(left)]
      if parents[int(left)] > 1: return false
    if right >= 0:
      inc parents[int(right)]
      if parents[int(right)] > 1: return false
  if parents[rootIndex] != 0: return false
  for index in 0 ..< nodeCount:
    if index != rootIndex and parents[index] != 1: return false

  var stackNode: array[MaxNodeCount, int]
  var stackLow: array[MaxNodeCount, int64]
  var stackHigh: array[MaxNodeCount, int64]
  var seen: array[MaxNodeCount, bool]
  var top = 1
  var visited = 0
  stackNode[0] = rootIndex
  stackLow[0] = 0
  stackHigh[0] = MaxValue + 1
  while top > 0:
    dec top
    let index = stackNode[top]
    if seen[index]: return false
    seen[index] = true
    inc visited
    let value = nodes[3 * index]
    let lower = stackLow[top]
    let upper = stackHigh[top]
    if value <= lower or value >= upper: return false
    let left = nodes[3 * index + 1]
    let right = nodes[3 * index + 2]
    if right >= 0:
      stackNode[top] = int(right)
      stackLow[top] = value
      stackHigh[top] = upper
      inc top
    if left >= 0:
      stackNode[top] = int(left)
      stackLow[top] = lower
      stackHigh[top] = value
      inc top
  visited == nodeCount

proc trimNode(nodes: ptr UncheckedArray[int64], node: int64, low, high: int64,
              output: ptr UncheckedArray[int64], outputCount: var int): int64 =
  if node == -1: return -1
  let index = int(node)
  let value = nodes[3 * index]
  let left = nodes[3 * index + 1]
  let right = nodes[3 * index + 2]
  if value < low: return trimNode(nodes, right, low, high, output, outputCount)
  if value > high: return trimNode(nodes, left, low, high, output, outputCount)
  let trimmedIndex = outputCount
  inc outputCount
  let offset = 1 + 3 * trimmedIndex
  output[offset] = value
  output[offset + 1] = -1
  output[offset + 2] = -1
  output[offset + 1] = trimNode(nodes, left, low, high, output, outputCount)
  output[offset + 2] = trimNode(nodes, right, low, high, output, outputCount)
  int64(trimmedIndex)

proc trim_bst*(nodes: ptr UncheckedArray[int64], nodeCount: csize_t, rootIndex: int64,
    low, high: int64, output: ptr UncheckedArray[int64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "trim_bst".} =
  if nodeCount > csize_t(MaxNodeCount) or low < 1 or high > MaxValue or low > high: return -1
  if nodeCount == 0:
    if rootIndex != -1: return -1
    if output.isNil or outputCapacity < 1: return -2
    output[0] = -1
    return 1
  if nodes.isNil or rootIndex < 0 or rootIndex >= int64(nodeCount): return -1
  let count = int(nodeCount)
  let root = int(rootIndex)
  if not validBst(nodes, count, root): return -1
  if output.isNil or outputCapacity < csize_t(1 + 3 * count): return -2
  var outputCount = 0
  output[0] = trimNode(nodes, rootIndex, low, high, output, outputCount)
  int64(1 + 3 * outputCount)
