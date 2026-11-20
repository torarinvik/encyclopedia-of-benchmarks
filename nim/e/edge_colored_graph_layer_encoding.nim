const MaxN = 8
const MaxM = 28
const MaxInput = 97
const MaxVertices = 24

proc putLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc edge_colored_graph_layer_encoding*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"edge_colored_graph_layer_encoding".} =
  if input.isNil or length < 5 or length > csize_t(MaxInput): return -1
  let n0, m0, d0, q0 = input[0], input[1], input[2], input[3]
  if n0 < 1 or n0 > 8 or m0 < 0 or m0 > 28 or d0 < 1 or d0 > 3 or q0 < 1 or q0 > 3: return -1
  let n, m, layers, classes = int(n0), int(m0), int(d0), int(q0)
  let edgeOffset = 4 + n
  if int(length) != edgeOffset + 3 * m: return -1
  var sourceColors: array[MaxN, int64]
  for vertex in 0..<n:
    sourceColors[vertex] = input[4 + vertex]
    if sourceColors[vertex] < 0 or sourceColors[vertex] >= q0: return -1
  var sourceEdges: array[MaxN, array[MaxN, uint8]]
  var offset = edgeOffset
  for _ in 0..<m:
    let u0, v0, color0 = input[offset], input[offset + 1], input[offset + 2]
    offset += 3
    if u0 < 0 or u0 >= n0 or v0 < 0 or v0 >= n0 or u0 == v0 or color0 < 1 or color0 >= (1'i64 shl d0): return -1
    var u, v = int(u0), int(v0)
    if u > v: swap(u, v)
    if sourceEdges[u][v] != 0: return -1
    sourceEdges[u][v] = uint8(color0)

  let nodes = n * layers
  var adjacency: array[MaxVertices, array[MaxVertices, bool]]
  for layer in 0..<layers:
    for u in 0..<n:
      for v in (u + 1)..<n:
        if (sourceEdges[u][v] and (1'u8 shl layer)) != 0:
          adjacency[layer * n + u][layer * n + v] = true
  for vertex in 0..<n:
    for layer in 0..<(layers - 1):
      adjacency[layer * n + vertex][(layer + 1) * n + vertex] = true
  var edgeCount = 0
  for u in 0..<nodes:
    for v in (u + 1)..<nodes:
      if adjacency[u][v]: inc edgeCount
  let bytes = 8 * (2 + nodes + 2 * edgeCount)
  if output.isNil or int(capacity) < bytes: return -2
  putLe(output, 0, int64(nodes))
  putLe(output, 8, int64(edgeCount))
  var word = 2
  for layer in 0..<layers:
    for vertex in 0..<n:
      putLe(output, 8 * word, int64(layer * classes) + sourceColors[vertex])
      inc word
  for u in 0..<nodes:
    for v in (u + 1)..<nodes:
      if adjacency[u][v]:
        putLe(output, 8 * word, int64(u)); inc word
        putLe(output, 8 * word, int64(v)); inc word
  int64(bytes)
