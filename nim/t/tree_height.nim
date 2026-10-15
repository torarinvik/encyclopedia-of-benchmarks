const MaxNodes = 1023
const MaxArcs = 2 * (MaxNodes - 1)

proc dfsHeight(node: int, head, to, next: var array[MaxNodes + 1, int],
    visited: var array[MaxNodes + 1, bool], dp: var array[MaxNodes + 1, int], reached: var int): int =
  visited[node] = true
  inc reached
  var childHeight = 1
  var arc = head[node]
  while arc >= 0:
    let child = to[arc]
    if not visited[child]:
      if dfsHeight(child, head, to, next, visited, dp, reached) < 0: return -1
      if dp[child] + 1 > childHeight: childHeight = dp[child] + 1
    arc = next[arc]
  dp[node] = childHeight
  childHeight

proc tree_height*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "tree_height".} =
  if values.isNil or length < 1: return -1
  if values[0] < 1 or values[0] > MaxNodes: return -1
  let count = int(values[0])
  if int(length) != 1 + 2 * (count - 1): return -1
  var head: array[MaxNodes + 1, int]
  var to: array[MaxArcs, int]
  var next: array[MaxArcs, int]
  var dp: array[MaxNodes + 1, int]
  var visited: array[MaxNodes + 1, bool]
  for node in 0 .. count: head[node] = -1
  var arcs = 0
  for edge in 0 ..< count - 1:
    let aValue = values[1 + 2 * edge]
    let bValue = values[2 + 2 * edge]
    if aValue < 1 or aValue > count or bValue < 1 or bValue > count or aValue == bValue: return -1
    let a = int(aValue); let b = int(bValue)
    to[arcs] = b; next[arcs] = head[a]; head[a] = arcs; inc arcs
    to[arcs] = a; next[arcs] = head[b]; head[b] = arcs; inc arcs
  var reached = 0
  let result = dfsHeight(1, head, to, next, visited, dp, reached)
  if result < 0 or reached != count: return -1
  int64(result)
