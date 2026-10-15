## Traverse a connected undirected graph from vertex zero in sorted-neighbor BFS order.
const MaxVertices = 40
const MaxEdges = 780

proc putI64(output: ptr UncheckedArray[uint8], slot: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[slot * 8 + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc bfs_connected_undirected_visit_order*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "bfs_connected_undirected_visit_order".} =
  if input == nil or length < 3: return -1
  if input[0] < 1 or input[0] > MaxVertices or input[1] < 0 or input[1] > MaxEdges or input[2] != 0: return -1
  let vertices = int(input[0])
  let edgeCount = int(input[1])
  if length != csize_t(3 + 2 * edgeCount): return -1

  var adjacency: array[MaxVertices, uint64]
  for edge in 0 ..< edgeCount:
    let leftValue = input[3 + 2 * edge]
    let rightValue = input[4 + 2 * edge]
    if leftValue < 0 or rightValue < 0 or leftValue >= int64(vertices) or rightValue >= int64(vertices): return -1
    let left = int(leftValue)
    let right = int(rightValue)
    adjacency[left] = adjacency[left] or (1'u64 shl right)
    adjacency[right] = adjacency[right] or (1'u64 shl left)

  var visited: array[MaxVertices, bool]
  var queue: array[MaxVertices, int]
  var order: array[MaxVertices, int]
  var head = 0
  var tail = 1
  var count = 0
  visited[0] = true
  queue[0] = 0
  while head < tail:
    let vertex = queue[head]
    inc head
    order[count] = vertex
    inc count
    for neighbor in 0 ..< vertices:
      if (adjacency[vertex] and (1'u64 shl neighbor)) != 0'u64 and not visited[neighbor]:
        visited[neighbor] = true
        queue[tail] = neighbor
        inc tail
  if count != vertices: return -1
  if output == nil or capacity < csize_t(vertices * 8): return -2
  for index in 0 ..< count: putI64(output, index, int64(order[index]))
  int64(count)
