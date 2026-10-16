const MaxVertices = 128

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc heavy_light_decomposition_metadata*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "heavy_light_decomposition_metadata".} =
  if input.isNil or length < 2: return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 1 or nValue > MaxVertices or mValue != nValue - 1: return -1
  let n = int(nValue)
  let m = int(mValue)
  if int(length) != 2 + 2 * m: return -1

  var adjacency: array[MaxVertices * MaxVertices, int]
  var degree: array[MaxVertices, int]
  for edge in 0 ..< m:
    let uValue = input[2 + 2 * edge]
    let vValue = input[3 + 2 * edge]
    if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue or uValue == vValue: return -1
    let u = int(uValue)
    let v = int(vValue)
    for i in 0 ..< degree[u]:
      if adjacency[u * MaxVertices + i] == v: return -1
    adjacency[u * MaxVertices + degree[u]] = v
    inc degree[u]
    adjacency[v * MaxVertices + degree[v]] = u
    inc degree[v]

  var parent: array[MaxVertices, int]
  var order: array[MaxVertices, int]
  var stack: array[MaxVertices, int]
  for vertex in 0 ..< n: parent[vertex] = -2
  parent[0] = -1
  var top = 1
  var orderCount = 0
  stack[0] = 0
  while top > 0:
    dec top
    let vertex = stack[top]
    order[orderCount] = vertex
    inc orderCount
    var i = degree[vertex]
    while i > 0:
      dec i
      let child = adjacency[vertex * MaxVertices + i]
      if parent[child] == -2:
        parent[child] = vertex
        stack[top] = child
        inc top
  if orderCount != n: return -1

  var subtreeSize: array[MaxVertices, int]
  var bigChild: array[MaxVertices, int]
  for index in countdown(n - 1, 0):
    let vertex = order[index]
    var bestSize = 0
    subtreeSize[vertex] = 1
    bigChild[vertex] = -1
    for i in 0 ..< degree[vertex]:
      let child = adjacency[vertex * MaxVertices + i]
      if parent[child] != vertex: continue
      subtreeSize[vertex] += subtreeSize[child]
      if subtreeSize[child] > bestSize:
        bestSize = subtreeSize[child]
        bigChild[vertex] = child

  var position: array[MaxVertices, int]
  var head: array[MaxVertices, int]
  var stackHead: array[MaxVertices, int]
  top = 1
  var nextPosition = 0
  stack[0] = 0
  stackHead[0] = 0
  while top > 0:
    dec top
    let vertex = stack[top]
    let chainHead = stackHead[top]
    position[vertex] = nextPosition
    inc nextPosition
    head[vertex] = chainHead
    var i = degree[vertex]
    while i > 0:
      dec i
      let child = adjacency[vertex * MaxVertices + i]
      if parent[child] == vertex and child != bigChild[vertex]:
        stack[top] = child
        stackHead[top] = child
        inc top
    if bigChild[vertex] >= 0:
      stack[top] = bigChild[vertex]
      stackHead[top] = chainHead
      inc top

  let required = (1 + 3 * n) * 8
  if output.isNil or int(capacity) < required: return -2
  var cursor = 0
  putI64(output, cursor * 8, nValue)
  inc cursor
  for vertex in 0 ..< n:
    putI64(output, cursor * 8, int64(position[vertex]))
    inc cursor
    putI64(output, cursor * 8, int64(head[vertex]))
    inc cursor
    putI64(output, cursor * 8, int64(bigChild[vertex]))
    inc cursor
  int64(required)
