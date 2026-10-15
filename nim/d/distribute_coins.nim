## Count coin transfers by combining postorder subtree excesses.
const MaxNodeCount = 100

proc absoluteI64(value: int64): int64 =
  if value < 0: -value else: value

proc analyze(nodes: ptr UncheckedArray[int64], node: int64,
    moves: var int64): int64 =
  if node == -1: return 1
  let index = int(node)
  let left = nodes[3 * index + 1]
  let right = nodes[3 * index + 2]
  let leftExcess = analyze(nodes, left, moves)
  let rightExcess = analyze(nodes, right, moves)
  moves += absoluteI64(1 - leftExcess) + absoluteI64(1 - rightExcess)
  nodes[3 * index] + leftExcess + rightExcess - 2

proc distribute_coins*(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    rootIndex: int64): int64 {.cdecl, exportc: "distribute_coins".} =
  if nodeCount > MaxNodeCount: return -1
  if nodeCount == 0: return (if rootIndex == -1: 0 else: -1)
  if nodes == nil or rootIndex < 0 or uint64(rootIndex) >= uint64(nodeCount): return -1
  let count = int(nodeCount)
  var parent: array[MaxNodeCount, int64]
  var stack: array[MaxNodeCount, int]
  var seen: array[MaxNodeCount, bool]
  for node in 0 ..< count: parent[node] = -1

  var coinTotal = 0'i64
  for node in 0 ..< count:
    let value = nodes[3 * node]
    if value < 0 or value > 100: return -1
    coinTotal += value
    for edge in 1 .. 2:
      let child = nodes[3 * node + edge]
      if child < -1 or (child >= 0 and uint64(child) >= uint64(count)): return -1
      if child >= 0:
        let childIndex = int(child)
        if parent[childIndex] != -1: return -1
        parent[childIndex] = int64(node)
  if coinTotal != int64(count): return -1
  let root = int(rootIndex)
  if parent[root] != -1: return -1
  for node in 0 ..< count:
    if node != root and parent[node] == -1: return -1

  var top = 0
  var reached = 0
  stack[top] = root
  inc top
  while top > 0:
    dec top
    let node = stack[top]
    if seen[node]: return -1
    seen[node] = true
    inc reached
    for edge in 1 .. 2:
      let child = nodes[3 * node + edge]
      if child >= 0:
        stack[top] = int(child)
        inc top
  if reached != count: return -1

  var moves = 0'i64
  discard analyze(nodes, rootIndex, moves)
  moves
