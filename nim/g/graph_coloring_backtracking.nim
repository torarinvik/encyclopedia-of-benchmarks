const MaxVertices = 64
const MaxEdges = 2016

proc colorVertex(vertex, count: int, adjacency: ptr UncheckedArray[bool],
    colors: ptr UncheckedArray[int64]): bool =
  if vertex == count: return true
  for color in 1 .. count:
    var safe = true
    for neighbor in 0 ..< count:
      if adjacency[vertex * MaxVertices + neighbor] and colors[neighbor] == int64(color):
        safe = false
        break
    if not safe: continue
    colors[vertex] = int64(color)
    if colorVertex(vertex + 1, count, adjacency, colors): return true
    colors[vertex] = 0
  false

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc graph_coloring_backtracking*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "graph_coloring_backtracking".} =
  if input == nil or length < 2: return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 0 or nValue > MaxVertices or mValue < 0 or mValue > MaxEdges or
      length != csize_t(2 + 2 * mValue): return -1
  let n = int(nValue)
  let m = int(mValue)
  var adjacency: array[MaxVertices * MaxVertices, bool]
  for edge in 0 ..< m:
    let uValue = input[2 + 2 * edge]
    let vValue = input[3 + 2 * edge]
    if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue or uValue == vValue:
      return -1
    let u = int(uValue)
    let v = int(vValue)
    adjacency[u * MaxVertices + v] = true
    adjacency[v * MaxVertices + u] = true
  var colors: array[MaxVertices, int64]
  if not colorVertex(0, n, cast[ptr UncheckedArray[bool]](addr adjacency[0]),
      cast[ptr UncheckedArray[int64]](addr colors[0])): return -1
  var colorsUsed = 0'i64
  for vertex in 0 ..< n:
    if colors[vertex] > colorsUsed: colorsUsed = colors[vertex]
  var packed: array[MaxVertices + 2, int64]
  packed[0] = nValue
  for vertex in 0 ..< n: packed[vertex + 1] = colors[vertex]
  packed[n + 1] = colorsUsed
  let used = n + 2
  let required = used * 8
  if output == nil or capacity < csize_t(required): return -2
  for index in 0 ..< used: putI64(output, index * 8, packed[index])
  int64(required)
