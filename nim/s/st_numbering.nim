const MaxVertices = 8
const MaxEdges = 28
const MaxArcs = 2 * MaxEdges
const MaxInput = 4 + 2 * MaxEdges

proc st_numbering*(input: ptr UncheckedArray[int64], inputLength: csize_t,
                   output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "st_numbering".} =
  if input == nil or inputLength < 4 or inputLength > MaxInput.csize_t:
    return -1
  let nValue = input[0]
  let mValue = input[1]
  let sValue = input[2]
  let tValue = input[3]
  if nValue < 2 or nValue > MaxVertices.int64 or mValue < 0 or mValue > MaxEdges.int64 or
      sValue < 0 or sValue >= nValue or tValue < 0 or tValue >= nValue or
      sValue == tValue or inputLength != csize_t(4 + 2 * mValue):
    return -1
  let n = int(nValue)
  let m = int(mValue)
  let s = int(sValue)
  let t = int(tValue)

  var edgeU: array[MaxEdges, int]
  var edgeV: array[MaxEdges, int]
  var adjacent: array[MaxVertices, uint16]
  var stEdge = -1
  for edge in 0 ..< m:
    let uValue = input[4 + 2 * edge]
    let vValue = input[5 + 2 * edge]
    if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue or uValue == vValue:
      return -1
    let u = int(uValue)
    let v = int(vValue)
    let uBit = 1'u16 shl v
    let vBit = 1'u16 shl u
    if (adjacent[u] and uBit) != 0'u16:
      return -1
    adjacent[u] = adjacent[u] or uBit
    adjacent[v] = adjacent[v] or vBit
    edgeU[edge] = u
    edgeV[edge] = v
    if (u == s and v == t) or (u == t and v == s):
      stEdge = edge
  if stEdge < 0:
    return -1

  var head: array[MaxVertices, int]
  for vertex in 0 ..< n: head[vertex] = -1
  var arcTo: array[MaxArcs, int]
  var arcNext: array[MaxArcs, int]
  var arcCount = 0
  for edge in 0 ..< m:
    if edge == stEdge: continue
    let u = edgeU[edge]
    let v = edgeV[edge]
    arcTo[arcCount] = v
    arcNext[arcCount] = head[u]
    head[u] = arcCount
    inc arcCount
    arcTo[arcCount] = u
    arcNext[arcCount] = head[v]
    head[v] = arcCount
    inc arcCount
  arcTo[arcCount] = t
  arcNext[arcCount] = head[s]
  head[s] = arcCount
  inc arcCount
  arcTo[arcCount] = s
  arcNext[arcCount] = head[t]
  head[t] = arcCount

  var parent: array[MaxVertices, int]
  var discovery: array[MaxVertices, int]
  var lowVertex: array[MaxVertices, int]
  var children: array[MaxVertices, int]
  var nextArc: array[MaxVertices, int]
  var preorder: array[MaxVertices, int]
  for vertex in 0 ..< n:
    parent[vertex] = -1
    lowVertex[vertex] = vertex
    nextArc[vertex] = -1
  var stack: array[MaxVertices, int]
  var top = 0
  var clock = 1
  var preorderCount = 1
  discovery[s] = clock
  preorder[0] = s
  nextArc[s] = head[s]
  stack[top] = s
  inc top
  while top > 0:
    let vertex = stack[top - 1]
    let arc = nextArc[vertex]
    if arc < 0:
      dec top
      let ancestor = parent[vertex]
      if ancestor >= 0 and discovery[lowVertex[vertex]] < discovery[lowVertex[ancestor]]:
        lowVertex[ancestor] = lowVertex[vertex]
      continue
    nextArc[vertex] = arcNext[arc]
    let neighbor = arcTo[arc]
    if neighbor == parent[vertex]: continue
    if discovery[neighbor] == 0:
      parent[neighbor] = vertex
      inc children[vertex]
      inc clock
      discovery[neighbor] = clock
      lowVertex[neighbor] = neighbor
      preorder[preorderCount] = neighbor
      inc preorderCount
      nextArc[neighbor] = head[neighbor]
      stack[top] = neighbor
      inc top
    elif discovery[neighbor] < discovery[vertex] and
        discovery[neighbor] < discovery[lowVertex[vertex]]:
      lowVertex[vertex] = neighbor

  if preorderCount != n or children[s] != 1: return -1
  for vertex in 0 ..< n:
    if vertex == s: continue
    for child in 0 ..< n:
      if parent[child] == vertex and discovery[lowVertex[child]] >= discovery[vertex]:
        return -1

  var previous: array[MaxVertices, int]
  var following: array[MaxVertices, int]
  var sign: array[MaxVertices, int]
  for vertex in 0 ..< n:
    previous[vertex] = -1
    following[vertex] = -1
  sign[s] = -1
  following[s] = t
  previous[t] = s
  var listHead = s
  for order in 2 ..< n:
    let vertex = preorder[order]
    let ancestor = parent[vertex]
    if sign[lowVertex[vertex]] == -1:
      let left = previous[ancestor]
      previous[vertex] = left
      following[vertex] = ancestor
      previous[ancestor] = vertex
      if left >= 0: following[left] = vertex
      else: listHead = vertex
      sign[ancestor] = 1
    else:
      let right = following[ancestor]
      previous[vertex] = ancestor
      following[vertex] = right
      following[ancestor] = vertex
      if right >= 0: previous[right] = vertex
      sign[ancestor] = -1

  var rank: array[MaxVertices, int]
  var staged: array[MaxVertices, uint8]
  var rankValue = 1
  var vertex = listHead
  while vertex >= 0 and rankValue <= n:
    rank[vertex] = rankValue
    staged[vertex] = uint8(rankValue)
    inc rankValue
    vertex = following[vertex]
  if rankValue != n + 1 or rank[s] != 1 or rank[t] != n: return -1
  for v in 0 ..< n:
    if v == s or v == t: continue
    var lower = false
    var higher = false
    var arc = head[v]
    while arc >= 0:
      let neighbor = arcTo[arc]
      lower = lower or rank[neighbor] < rank[v]
      higher = higher or rank[neighbor] > rank[v]
      arc = arcNext[arc]
    if not lower or not higher: return -1

  if output == nil or outputCapacity < csize_t(n): return -2
  for v in 0 ..< n: output[v] = staged[v]
  int64(n)
