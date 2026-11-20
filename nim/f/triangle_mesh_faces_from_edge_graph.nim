const MaxVertices = 8
const MaxEdges = 28
const MaxTriangles = 56
const MaxInputWords = 59
const MaxOutputWords = 170

type Triangle = object
  a, b, c: int
  e0, e1, e2: int
  active: bool

proc selectTriangle(chosen: int, triangles: var array[MaxTriangles, Triangle],
    triangleCount: int, incidence: var array[MaxEdges, int],
    used: var array[MaxEdges, int], staged: var array[MaxOutputWords, int64],
    faceCount: var int) =
  let t = triangles[chosen]
  triangles[chosen].active = false
  staged[2 + 3 * faceCount] = int64(t.a)
  staged[3 + 3 * faceCount] = int64(t.b)
  staged[4 + 3 * faceCount] = int64(t.c)
  inc faceCount
  let edges = [t.e0, t.e1, t.e2]
  var saturated: array[MaxEdges, bool]
  for edge in edges:
    dec incidence[edge]
    inc used[edge]
    if used[edge] == 2: saturated[edge] = true
  for other in 0 ..< triangleCount:
    if not triangles[other].active: continue
    let candidate = triangles[other]
    if saturated[candidate.e0] or saturated[candidate.e1] or saturated[candidate.e2]:
      triangles[other].active = false
      dec incidence[candidate.e0]
      dec incidence[candidate.e1]
      dec incidence[candidate.e2]

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc triangle_mesh_faces_from_edge_graph*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "triangle_mesh_faces_from_edge_graph".} =
  if input == nil or length < 2 or length > MaxInputWords: return -1
  let vertexWord = input[0]
  let edgeWord = input[1]
  if vertexWord < 3 or vertexWord > MaxVertices or edgeWord < 0 or edgeWord > MaxEdges: return -1
  let vertices = int(vertexWord)
  let edgeCount = int(edgeWord)
  if edgeCount > vertices * (vertices - 1) div 2 or length != csize_t(2 + 2 * edgeCount): return -1

  var edgeIndex: array[MaxVertices, array[MaxVertices, int]]
  for a in 0 ..< MaxVertices:
    for b in 0 ..< MaxVertices: edgeIndex[a][b] = -1
  var vertexDegree: array[MaxVertices, int]
  for edge in 0 ..< edgeCount:
    let leftWord = input[2 + 2 * edge]
    let rightWord = input[3 + 2 * edge]
    if leftWord < 0 or leftWord >= vertexWord or rightWord < 0 or rightWord >= vertexWord or leftWord == rightWord: return -1
    var left = int(leftWord)
    var right = int(rightWord)
    if left > right: swap(left, right)
    if edgeIndex[left][right] >= 0: return -1
    edgeIndex[left][right] = edge
    edgeIndex[right][left] = edge
    inc vertexDegree[left]
    inc vertexDegree[right]

  var triangles: array[MaxTriangles, Triangle]
  var triangleCount = 0
  var incidence: array[MaxEdges, int]
  for a in 0 ..< vertices:
    for b in a + 1 ..< vertices:
      for c in b + 1 ..< vertices:
        let e0 = edgeIndex[a][b]
        let e1 = edgeIndex[a][c]
        let e2 = edgeIndex[b][c]
        if e0 >= 0 and e1 >= 0 and e2 >= 0:
          triangles[triangleCount] = Triangle(a: a, b: b, c: c, e0: e0, e1: e1, e2: e2, active: true)
          inc triangleCount
          inc incidence[e0]
          inc incidence[e1]
          inc incidence[e2]

  var used: array[MaxEdges, int]
  var staged: array[MaxOutputWords, int64]
  var faceCount = 0
  var fallbackUsed = false
  while true:
    var chosen = triangleCount
    for index in 0 ..< triangleCount:
      let t = triangles[index]
      if t.active and (vertexDegree[t.a] == 3 or vertexDegree[t.b] == 3 or vertexDegree[t.c] == 3):
        chosen = index
        break
    if chosen < triangleCount:
      selectTriangle(chosen, triangles, triangleCount, incidence, used, staged, faceCount)
      continue

    var forced: array[MaxEdges, bool]
    for edge in 0 ..< edgeCount: forced[edge] = incidence[edge] > 0 and incidence[edge] == 2 - used[edge]
    chosen = triangleCount
    for index in 0 ..< triangleCount:
      let t = triangles[index]
      if t.active and (forced[t.e0] or forced[t.e1] or forced[t.e2]):
        chosen = index
        break
    if chosen < triangleCount:
      selectTriangle(chosen, triangles, triangleCount, incidence, used, staged, faceCount)
      continue

    var bestScore = 3 * MaxTriangles + 1
    chosen = triangleCount
    for index in 0 ..< triangleCount:
      let t = triangles[index]
      if not t.active: continue
      let score = incidence[t.e0] + incidence[t.e1] + incidence[t.e2]
      if score < bestScore:
        bestScore = score
        chosen = index
    if chosen == triangleCount: break
    fallbackUsed = true
    selectTriangle(chosen, triangles, triangleCount, incidence, used, staged, faceCount)

  var complete = edgeCount > 0
  for edge in 0 ..< edgeCount:
    if used[edge] != 2: complete = false
  staged[0] = (if complete: 0'i64 else: 2'i64) + (if fallbackUsed: 1'i64 else: 0'i64)
  staged[1] = int64(faceCount)
  let outputBytes = (2 + 3 * faceCount) * 8
  if output == nil or capacity < csize_t(outputBytes): return -2
  for word in 0 ..< 2 + 3 * faceCount: storeI64Le(output, word * 8, staged[word])
  int64(outputBytes)
