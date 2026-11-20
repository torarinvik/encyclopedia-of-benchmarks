const MaxN = 16
const MaxEdges = MaxN - 1
const MaxArcs = 2 * MaxEdges
const MaxInputLength = 48

proc findRoot(sets: var array[MaxN, int32], vertexValue: int): int =
  var vertex = vertexValue
  while sets[vertex] != int32(vertex):
    sets[vertex] = sets[int(sets[vertex])]
    vertex = int(sets[vertex])
  vertex

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc tree_random_walk_edge_hitting_cost*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tree_random_walk_edge_hitting_cost".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let rootValue = input[1]
  if nValue < 1 or nValue > int64(MaxN) or rootValue < 0 or rootValue >= nValue: return -1
  let n = int(nValue)
  let root = int(rootValue)
  let edgeCount = n - 1
  if length != csize_t(2 + 3 * edgeCount): return -1

  var head: array[MaxN, int32]
  var to: array[MaxArcs, int32]
  var nextArc: array[MaxArcs, int32]
  var sets: array[MaxN, int32]
  var inputU, inputV: array[MaxEdges, int]
  var incidentSum, down, up: array[MaxN, int64]
  for vertex in 0 ..< n:
    head[vertex] = -1
    sets[vertex] = int32(vertex)

  var arcCount = 0
  for edge in 0 ..< edgeCount:
    let offset = 2 + 3 * edge
    let uValue = input[offset]
    let vValue = input[offset + 1]
    let weight = input[offset + 2]
    if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue
        or uValue == vValue or weight < 1 or weight > 9: return -1
    let u = int(uValue)
    let v = int(vValue)
    let setU = findRoot(sets, u)
    let setV = findRoot(sets, v)
    if setU == setV: return -1
    sets[setV] = int32(setU)
    inputU[edge] = u
    inputV[edge] = v
    to[arcCount] = int32(v)
    nextArc[arcCount] = head[u]
    head[u] = int32(arcCount)
    inc arcCount
    to[arcCount] = int32(u)
    nextArc[arcCount] = head[v]
    head[v] = int32(arcCount)
    inc arcCount
    incidentSum[u] += weight
    incidentSum[v] += weight

  let outputBytes = 16 * edgeCount
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var parent: array[MaxN, int32]
  var order: array[MaxN, int]
  for vertex in 0 ..< n: parent[vertex] = -1
  parent[root] = int32(root)
  order[0] = root
  var orderSize = 1
  var cursor = 0
  while cursor < orderSize:
    let vertex = order[cursor]
    var arc = head[vertex]
    while arc >= 0:
      let index = int(arc)
      let neighbor = int(to[index])
      if parent[neighbor] == -1:
        parent[neighbor] = int32(vertex)
        order[orderSize] = neighbor
        inc orderSize
      arc = nextArc[index]
    inc cursor

  for position in countdown(n - 1, 0):
    let vertex = order[position]
    down[vertex] = incidentSum[vertex]
    var arc = head[vertex]
    while arc >= 0:
      let index = int(arc)
      let child = int(to[index])
      if parent[child] == int32(vertex): down[vertex] += down[child]
      arc = nextArc[index]
  for position in 0 ..< n:
    let vertex = order[position]
    var arc = head[vertex]
    while arc >= 0:
      let index = int(arc)
      let child = int(to[index])
      if parent[child] == int32(vertex):
        up[child] = up[vertex] + down[vertex] - down[child]
      arc = nextArc[index]

  for edge in 0 ..< edgeCount:
    let u = inputU[edge]
    let v = inputV[edge]
    var towardV, towardU: int64
    if parent[u] == int32(v):
      towardV = down[u]
      towardU = up[u]
    else:
      towardV = up[v]
      towardU = down[v]
    storeI64Le(output, 16 * edge, towardV)
    storeI64Le(output, 16 * edge + 8, towardU)
  int64(outputBytes)
