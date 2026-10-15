const MaxNodeCount = 1023
const MaxValue = 100000'i64

proc range_sum_bst*(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    rootIndex, low, high: int64): int64 {.cdecl, exportc: "range_sum_bst".} =
  if nodeCount > MaxNodeCount or low < 1 or high > MaxValue or low > high: return -1
  if nodeCount == 0: return (if rootIndex == -1: 0 else: -1)
  if nodes == nil or rootIndex < 0 or uint64(rootIndex) >= uint64(nodeCount): return -1

  var parents: array[MaxNodeCount, int64]
  var seen: array[MaxNodeCount, bool]
  var stackNode, stackLow, stackHigh: array[MaxNodeCount, int64]
  for index in 0 ..< int(nodeCount):
    let value = nodes[3 * index]
    let left = nodes[3 * index + 1]
    let right = nodes[3 * index + 2]
    if value < 1 or value > MaxValue or left < -1 or right < -1 or
        (left >= 0 and uint64(left) >= uint64(nodeCount)) or
        (right >= 0 and uint64(right) >= uint64(nodeCount)): return -1
    if left >= 0:
      inc parents[int(left)]
      if parents[int(left)] > 1: return -1
    if right >= 0:
      inc parents[int(right)]
      if parents[int(right)] > 1: return -1
  let root = int(rootIndex)
  if parents[root] != 0: return -1
  for index in 0 ..< int(nodeCount):
    if index != root and parents[index] != 1: return -1

  var top = 1
  var visited = 0
  stackNode[0] = rootIndex
  stackLow[0] = 0
  stackHigh[0] = MaxValue + 1
  var total = 0'i64
  while top > 0:
    dec top
    let index = int(stackNode[top])
    let lower = stackLow[top]
    let upper = stackHigh[top]
    if seen[index]: return -1
    seen[index] = true
    inc visited
    let value = nodes[3 * index]
    let left = nodes[3 * index + 1]
    let right = nodes[3 * index + 2]
    if value <= lower or value >= upper: return -1
    if low <= value and value <= high: total += value
    if right >= 0:
      stackNode[top] = right
      stackLow[top] = value
      stackHigh[top] = upper
      inc top
    if left >= 0:
      stackNode[top] = left
      stackLow[top] = lower
      stackHigh[top] = value
      inc top
  if visited != int(nodeCount): return -1
  return total
