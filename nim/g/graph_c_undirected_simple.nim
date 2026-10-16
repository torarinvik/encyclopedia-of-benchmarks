## Normalize the simple undirected C graph ADT to a row-major adjacency matrix.
const MaxVertices = 32
const MaxEdges = 2047

proc putI64(output: ptr UncheckedArray[uint8], slot: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[slot * 8 + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc graph_c_undirected_simple*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "graph_c_undirected_simple".} =
  if input == nil or length < 2: return -1
  if input[0] < 1 or input[0] > MaxVertices or input[1] < 0 or input[1] > MaxEdges: return -1
  let vertices = int(input[0])
  let edgeCount = int(input[1])
  if length != csize_t(2 + 2 * edgeCount): return -1

  var adjacency: array[MaxVertices * MaxVertices, int64]
  for edge in 0 ..< edgeCount:
    let leftValue = input[2 + 2 * edge]
    let rightValue = input[3 + 2 * edge]
    if leftValue < 0 or rightValue < 0 or leftValue >= int64(vertices) or rightValue >= int64(vertices): return -1
    let left = int(leftValue)
    let right = int(rightValue)
    adjacency[left * vertices + right] = 1
    adjacency[right * vertices + left] = 1
  let count = vertices * vertices
  if output == nil or capacity < csize_t(count * 8): return -2
  for row in 0 ..< vertices:
    for column in 0 ..< vertices:
      putI64(output, row * vertices + column, adjacency[row * vertices + column])
  int64(count * 8)
