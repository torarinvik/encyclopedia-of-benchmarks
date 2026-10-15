const MaxNodes = 256
const MaxQueries = 1024
const MaxArcs = 510
const LogLevels = 9
const InvalidResult = -1'i64

type I64Input = ptr UncheckedArray[int64]
type ByteOutput = ptr UncheckedArray[uint8]

proc lowest_common_ancestor_binary_lifting*(input: I64Input, length: csize_t,
    output: ByteOutput, outputCapacity: csize_t): int64 {.cdecl, exportc: "lowest_common_ancestor_binary_lifting".} =
  if input.isNil or length < 4: return InvalidResult
  if input[0] < 1'i64 or input[0] > MaxNodes: return InvalidResult
  let n = int(input[0])
  if input[1] < 0'i64 or input[1] >= int64(n) or input[2] != int64(n - 1) or
      input[3] < 0'i64 or input[3] > MaxQueries: return InvalidResult
  let m = int(input[2])
  let q = int(input[3])
  let queryOffset = 4 + 2 * m
  if int(length) != queryOffset + 2 * q: return InvalidResult
  let root = int(input[1])
  var head: array[MaxNodes, int]
  var arcTo: array[MaxArcs, int]
  var arcNext: array[MaxArcs, int]
  var parent: array[MaxNodes, int]
  var depth: array[MaxNodes, int]
  var up: array[LogLevels, array[MaxNodes, int]]
  var stack: array[MaxNodes, int]
  for node in 0 ..< n:
    head[node] = -1
    parent[node] = -2
  var arcs = 0
  for edge in 0 ..< m:
    let leftValue = input[4 + 2 * edge]
    let rightValue = input[5 + 2 * edge]
    if leftValue < 0'i64 or leftValue >= int64(n) or rightValue < 0'i64 or rightValue >= int64(n) or leftValue == rightValue:
      return InvalidResult
    let left = int(leftValue)
    let right = int(rightValue)
    arcTo[arcs] = right; arcNext[arcs] = head[left]; head[left] = arcs; inc arcs
    arcTo[arcs] = left; arcNext[arcs] = head[right]; head[right] = arcs; inc arcs
  for query in 0 ..< q:
    for side in 0 .. 1:
      let node = input[queryOffset + 2 * query + side]
      if node < 0'i64 or node >= int64(n): return InvalidResult
  var top = 0
  var reached = 0
  parent[root] = -1
  up[0][root] = root
  stack[top] = root
  inc top
  while top > 0:
    dec top
    let node = stack[top]
    inc reached
    var arc = head[node]
    while arc >= 0:
      let neighbor = arcTo[arc]
      if neighbor != parent[node]:
        if parent[neighbor] != -2: return InvalidResult
        parent[neighbor] = node
        depth[neighbor] = depth[node] + 1
        up[0][neighbor] = node
        stack[top] = neighbor
        inc top
      arc = arcNext[arc]
  if reached != n: return InvalidResult
  if outputCapacity < csize_t(q) or (q > 0 and output.isNil): return -2
  for level in 1 ..< LogLevels:
    for node in 0 ..< n: up[level][node] = up[level - 1][up[level - 1][node]]
  for query in 0 ..< q:
    var u = int(input[queryOffset + 2 * query])
    var v = int(input[queryOffset + 2 * query + 1])
    if depth[u] < depth[v]: swap(u, v)
    let difference = depth[u] - depth[v]
    for level in 0 ..< LogLevels:
      if (difference and (1 shl level)) != 0: u = up[level][u]
    if u != v:
      for level in countdown(LogLevels - 1, 0):
        if up[level][u] != up[level][v]:
          u = up[level][u]
          v = up[level][v]
      u = up[0][u]
    output[query] = uint8(u)
  int64(q)
