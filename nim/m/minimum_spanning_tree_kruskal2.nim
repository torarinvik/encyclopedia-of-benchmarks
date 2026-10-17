const MaxVertices = 16
const MaxEdges = 64
const MaxInputWords = 194
const MaxOutputWords = 1 + 3 * (MaxVertices - 1)
const MaxOutputBytes = 4 * MaxOutputWords

type
  Edge = object
    u, v, weight: int32

proc findRoot(parent: var array[MaxVertices, int], node: int): int =
  var current = node
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  current

proc putI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u32)

proc minimum_spanning_tree_kruskal2*(input: ptr UncheckedArray[int32], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "minimum_spanning_tree_kruskal2".} =
  if input == nil or length < 2 or length > csize_t(MaxInputWords): return -1
  let vertexCountRaw = input[0]
  let edgeCountRaw = input[1]
  if vertexCountRaw < 1 or vertexCountRaw > MaxVertices or edgeCountRaw < 0 or edgeCountRaw > MaxEdges: return -1
  let vertexCount = int(vertexCountRaw)
  let edgeCount = int(edgeCountRaw)
  if int(length) != 2 + 3 * edgeCount: return -1

  var inputEdges: array[MaxEdges, Edge]
  var seen: array[MaxVertices, array[MaxVertices, bool]]
  var pos = 2
  for i in 0 ..< edgeCount:
    let u = input[pos]
    let v = input[pos + 1]
    let weight = input[pos + 2]
    pos += 3
    if u < 0 or v <= u or v >= int32(vertexCount) or seen[int(u)][int(v)]: return -1
    seen[int(u)][int(v)] = true
    inputEdges[i] = Edge(u: u, v: v, weight: weight)

  var visited: array[MaxVertices, bool]
  var stack: array[MaxVertices, int]
  var stackSize = 1
  var reached = 0
  stack[0] = 0
  visited[0] = true
  while stackSize > 0:
    dec stackSize
    let node = stack[stackSize]
    inc reached
    for neighbor in 0 ..< vertexCount:
      if (seen[node][neighbor] or seen[neighbor][node]) and not visited[neighbor]:
        visited[neighbor] = true
        stack[stackSize] = neighbor
        inc stackSize
  if reached != vertexCount: return -1

  var ordered: array[MaxEdges, Edge]
  var orderedCount = 0
  for u in 0 ..< vertexCount:
    for i in 0 ..< edgeCount:
      if inputEdges[i].u == int32(u):
        ordered[orderedCount] = inputEdges[i]
        inc orderedCount
  for i in 1 ..< orderedCount:
    let key = ordered[i]
    var j = i
    while j > 0 and ordered[j - 1].weight > key.weight:
      ordered[j] = ordered[j - 1]
      dec j
    ordered[j] = key

  var parent: array[MaxVertices, int]
  var rank: array[MaxVertices, int]
  for i in 0 ..< vertexCount: parent[i] = i
  var words: array[MaxOutputWords, int32]
  var wordCount = 1
  var accepted = 0
  for i in 0 ..< orderedCount:
    if accepted == vertexCount - 1: break
    let rootU = findRoot(parent, int(ordered[i].u))
    let rootV = findRoot(parent, int(ordered[i].v))
    if rootU == rootV: continue
    if rank[rootU] < rank[rootV]: parent[rootU] = rootV
    elif rank[rootU] > rank[rootV]: parent[rootV] = rootU
    else:
      parent[rootU] = rootV
      inc rank[rootV]
    words[wordCount] = ordered[i].u
    words[wordCount + 1] = ordered[i].v
    words[wordCount + 2] = ordered[i].weight
    wordCount += 3
    inc accepted
  if accepted != vertexCount - 1: return -1
  words[0] = int32(accepted)
  let bytes = wordCount * 4
  if output == nil or capacity < csize_t(bytes): return -2
  var buffer: array[MaxOutputBytes, uint8]
  for i in 0 ..< wordCount: putI32Le(cast[ptr UncheckedArray[uint8]](addr buffer[0]), i * 4, words[i])
  for i in 0 ..< bytes: output[i] = buffer[i]
  int64(bytes)
