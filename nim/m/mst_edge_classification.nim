const MaxVertices = 12
const MaxEdges = 24
const MaxInputLength = 2 + 3 * MaxEdges + 1

proc findRoot(parent: var array[MaxVertices, int], vertex: int): int =
  var root = vertex
  while parent[root] != root: root = parent[root]
  var current = vertex
  while parent[current] != current:
    let next = parent[current]
    parent[current] = root
    current = next
  root

proc joinRoots(parent: var array[MaxVertices, int], left, right: int) =
  let a = findRoot(parent, left)
  let b = findRoot(parent, right)
  if a != b: parent[b] = a

proc alternativePathExists(left, right, edgeId: array[MaxEdges, int], edgeCount,
    omitted, source, target: int): bool =
  var seen: array[MaxVertices, bool]
  var queue: array[MaxVertices, int]
  var head = 0
  var tail = 0
  seen[source] = true
  queue[tail] = source
  inc tail
  while head < tail:
    let vertex = queue[head]
    inc head
    if vertex == target: return true
    for edge in 0 ..< edgeCount:
      if edgeId[edge] == omitted: continue
      var neighbor = -1
      if left[edge] == vertex: neighbor = right[edge]
      elif right[edge] == vertex: neighbor = left[edge]
      if neighbor >= 0 and not seen[neighbor]:
        seen[neighbor] = true
        queue[tail] = neighbor
        inc tail
  false

proc mst_edge_classification*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "mst_edge_classification".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  if input[0] < 1'i64 or input[0] > int64(MaxVertices) or
      input[1] < 0'i64 or input[1] > int64(MaxEdges): return -1
  let vertexCount = int(input[0])
  let edgeCount = int(input[1])
  if int(length) != 2 + 3 * edgeCount: return -1

  var left, right, weight, order: array[MaxEdges, int]
  var classes: array[MaxEdges, uint8]
  for edge in 0 ..< edgeCount:
    let u = input[2 + 3 * edge]
    let v = input[3 + 3 * edge]
    let w = input[4 + 3 * edge]
    if u < 0'i64 or u >= v or v >= int64(vertexCount) or w < 0'i64 or w > 20'i64:
      return -1
    left[edge] = int(u)
    right[edge] = int(v)
    weight[edge] = int(w)
    order[edge] = edge
    for prior in 0 ..< edge:
      if left[prior] == left[edge] and right[prior] == right[edge]: return -1
  for i in 1 ..< edgeCount:
    let item = order[i]
    var j = i
    while j > 0 and (weight[order[j - 1]] > weight[item] or
        (weight[order[j - 1]] == weight[item] and order[j - 1] > item)):
      order[j] = order[j - 1]
      dec j
    order[j] = item

  var parent: array[MaxVertices, int]
  for vertex in 0 ..< vertexCount: parent[vertex] = vertex
  var start = 0
  while start < edgeCount:
    var stop = start + 1
    let groupWeight = weight[order[start]]
    while stop < edgeCount and weight[order[stop]] == groupWeight: inc stop
    var qLeft, qRight, qId: array[MaxEdges, int]
    var qCount = 0
    for pos in start ..< stop:
      let id = order[pos]
      let a = findRoot(parent, left[id])
      let b = findRoot(parent, right[id])
      if a != b:
        qLeft[qCount] = a
        qRight[qCount] = b
        qId[qCount] = id
        inc qCount
    for edge in 0 ..< qCount:
      classes[qId[edge]] = if alternativePathExists(qLeft, qRight, qId, qCount,
        qId[edge], qLeft[edge], qRight[edge]): 1'u8 else: 2'u8
    for pos in start ..< stop:
      let id = order[pos]
      joinRoots(parent, left[id], right[id])
    start = stop
  let representative = findRoot(parent, 0)
  for vertex in 1 ..< vertexCount:
    if findRoot(parent, vertex) != representative: return -1
  if outputCapacity < csize_t(edgeCount) or (edgeCount > 0 and output.isNil): return -2
  for edge in 0 ..< edgeCount: output[edge] = classes[edge]
  int64(edgeCount)
