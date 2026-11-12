const MaxN = 32
const MaxInput = 5 * MaxN - 3
const Mod = 998_244_353'i64

proc findRoot(parent: var array[MaxN, int], item: int): int =
  var node = item
  while parent[node] != node:
    parent[node] = parent[parent[node]]
    node = parent[node]
  node

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc tree_path_composite_sum*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tree_path_composite_sum".} =
  if input == nil or length < 2 or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  if int(length) != 1 + n + 4 * (n - 1): return -1

  var vertexValue: array[MaxN, int64]
  for vertex in 0 ..< n:
    vertexValue[vertex] = input[1 + vertex]
    if vertexValue[vertex] < 0 or vertexValue[vertex] >= Mod: return -1
  var adjacent: array[MaxN, array[MaxN, bool]]
  var multiplier, addend: array[MaxN, array[MaxN, int64]]
  var dsuParent, dsuSize: array[MaxN, int]
  for vertex in 0 ..< n:
    dsuParent[vertex] = vertex
    dsuSize[vertex] = 1
  var offset = 1 + n
  for _ in 0 ..< n - 1:
    let uValue = input[offset]
    let vValue = input[offset + 1]
    let b = input[offset + 2]
    let c = input[offset + 3]
    offset += 4
    if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue or
        uValue == vValue or b < 1 or b >= Mod or c < 0 or c >= Mod: return -1
    let u = int(uValue)
    let v = int(vValue)
    var rootU = findRoot(dsuParent, u)
    var rootV = findRoot(dsuParent, v)
    if rootU == rootV: return -1
    if dsuSize[rootU] < dsuSize[rootV]: swap(rootU, rootV)
    dsuParent[rootV] = rootU
    dsuSize[rootU] += dsuSize[rootV]
    adjacent[u][v] = true
    adjacent[v][u] = true
    multiplier[u][v] = b
    multiplier[v][u] = b
    addend[u][v] = c
    addend[v][u] = c

  var order, stack: array[MaxN, int]
  var parent: array[MaxN, int]
  for vertex in 0 ..< n: parent[vertex] = -2
  parent[0] = -1
  var top = 1
  var orderCount = 0
  stack[0] = 0
  while top > 0:
    dec top
    let u = stack[top]
    order[orderCount] = u
    inc orderCount
    for v in 0 ..< n:
      if adjacent[u][v] and v != parent[u]:
        parent[v] = u
        stack[top] = v
        inc top

  var downSum, upSum, answer: array[MaxN, int64]
  var downCount, upCount: array[MaxN, int]
  for position in countdown(orderCount - 1, 0):
    let u = order[position]
    downSum[u] = vertexValue[u]
    downCount[u] = 1
    for v in 0 ..< n:
      if adjacent[u][v] and parent[v] == u:
        let contribution = (multiplier[u][v] * downSum[v] +
          addend[u][v] * int64(downCount[v])) mod Mod
        downSum[u] = (downSum[u] + contribution) mod Mod
        downCount[u] += downCount[v]

  for position in 0 ..< orderCount:
    let u = order[position]
    var totalSum = vertexValue[u]
    var totalCount = 1
    if parent[u] >= 0:
      totalSum = (totalSum + upSum[u]) mod Mod
      totalCount += upCount[u]
    for v in 0 ..< n:
      if adjacent[u][v] and parent[v] == u:
        totalSum = (totalSum + multiplier[u][v] * downSum[v] +
          addend[u][v] * int64(downCount[v])) mod Mod
        totalCount += downCount[v]
    answer[u] = totalSum
    for v in 0 ..< n:
      if adjacent[u][v] and parent[v] == u:
        let contribution = (multiplier[u][v] * downSum[v] +
          addend[u][v] * int64(downCount[v])) mod Mod
        let outsideSum = (totalSum - contribution + Mod) mod Mod
        let outsideCount = totalCount - downCount[v]
        upSum[v] = (multiplier[u][v] * outsideSum +
          addend[u][v] * int64(outsideCount)) mod Mod
        upCount[v] = outsideCount

  let required = 8 * n
  if output == nil or int(capacity) < required: return -2
  for vertex in 0 ..< n: storeLe(output, 8 * vertex, answer[vertex])
  int64(required)
