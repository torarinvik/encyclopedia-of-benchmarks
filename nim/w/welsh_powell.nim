const MaxVertices = 32
const MaxEdgePairs = 512
const MaxValidationLength = 2 + 2 * MaxEdgePairs + 1
const OutputBytesPerVertex = 8

proc vertexBit(vertex: int): uint64 =
  1'u64 shl vertex

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< OutputBytesPerVertex:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc welsh_powell*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "welsh_powell".} =
  if input.isNil or length < 2 or length > csize_t(MaxValidationLength): return -1
  let n64 = input[0]
  let edgeCount64 = input[1]
  if n64 < 0 or n64 > int64(MaxVertices) or edgeCount64 < 0 or edgeCount64 > int64(MaxEdgePairs): return -1
  let n = int(n64)
  let edgeCount = int(edgeCount64)
  if length != csize_t(2 + 2 * edgeCount): return -1

  var adjacency: array[MaxVertices, uint64]
  for edge in 0 ..< edgeCount:
    let left64 = input[2 + 2 * edge]
    let right64 = input[3 + 2 * edge]
    if left64 < 0 or left64 >= n64 or right64 < 0 or right64 >= n64 or left64 == right64: return -1
    let left = int(left64)
    let right = int(right64)
    adjacency[left] = adjacency[left] or vertexBit(right)
    adjacency[right] = adjacency[right] or vertexBit(left)

  let outputBytes = n * OutputBytesPerVertex
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var degrees: array[MaxVertices, int]
  var order: array[MaxVertices, int]
  var colors: array[MaxVertices, int64]
  for vertex in 0 ..< n:
    colors[vertex] = -1
    order[vertex] = vertex
    for neighbor in 0 ..< n:
      if (adjacency[vertex] and vertexBit(neighbor)) != 0: inc degrees[vertex]

  # Stable descending degree order keeps equal-degree vertices by index.
  for index in 1 ..< n:
    let key = order[index]
    var position = index
    while position > 0 and degrees[order[position - 1]] < degrees[key]:
      order[position] = order[position - 1]
      dec position
    order[position] = key

  var coloredVertices: uint64 = 0
  for index in 0 ..< n:
    let vertex = order[index]
    if colors[vertex] >= 0: continue
    var usedColors: uint64 = 0
    for neighbor in 0 ..< n:
      if (adjacency[vertex] and vertexBit(neighbor)) != 0 and colors[neighbor] >= 0:
        usedColors = usedColors or vertexBit(int(colors[neighbor]))
    var color = 0
    while (usedColors and vertexBit(color)) != 0: inc color
    colors[vertex] = int64(color)
    coloredVertices = coloredVertices or vertexBit(vertex)
    for otherIndex in 0 ..< n:
      let other = order[otherIndex]
      if colors[other] < 0 and (adjacency[other] and coloredVertices) == 0:
        colors[other] = int64(color)
        coloredVertices = coloredVertices or vertexBit(other)

  for vertex in 0 ..< n:
    putI64Le(output, vertex * OutputBytesPerVertex, colors[vertex])
  int64(outputBytes)
