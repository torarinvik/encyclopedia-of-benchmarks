const MaxVertices = 8
const MaxColors = 4
const MaxValidationLength = 11
const OutputBytes = 8

proc countFrom(masks: array[MaxVertices, uint8], colors: var array[MaxVertices, uint8],
               vertexCount, colorCount, vertex: int): int64 =
  if vertex == vertexCount: return 1
  for color in 0 ..< colorCount:
    var safe = true
    for prior in 0 ..< vertex:
      if (masks[vertex] and (1'u8 shl prior)) != 0 and int(colors[prior]) == color:
        safe = false
        break
    if safe:
      colors[vertex] = uint8(color)
      result += countFrom(masks, colors, vertexCount, colorCount, vertex + 1)

proc putI64Le(output: ptr UncheckedArray[uint8], value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< OutputBytes:
    output[byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc graph_coloring*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "graph_coloring".} =
  if input.isNil or length < 2 or length > csize_t(MaxValidationLength): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > int64(MaxVertices) or m64 < 1 or m64 > int64(MaxColors): return -1
  let n = int(n64)
  let m = int(m64)
  if length != csize_t(n + 2): return -1

  var masks: array[MaxVertices, uint8]
  var colors: array[MaxVertices, uint8]
  let maskLimit = 1'i64 shl n
  for vertex in 0 ..< n:
    let row = input[2 + vertex]
    if row < 0 or row >= maskLimit: return -1
    masks[vertex] = uint8(row)
    if (masks[vertex] and (1'u8 shl vertex)) != 0: return -1
  for vertex in 0 ..< n:
    for neighbor in 0 ..< n:
      let edge = (masks[vertex] and (1'u8 shl neighbor)) != 0
      let reverseEdge = (masks[neighbor] and (1'u8 shl vertex)) != 0
      if edge != reverseEdge: return -1
  if output.isNil or capacity < csize_t(OutputBytes): return -2

  putI64Le(output, countFrom(masks, colors, n, m, 0))
  OutputBytes.int64
