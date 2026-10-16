## Recursive reachability search in a bounded undirected graph.
const MaxVertices = 64
const MaxEdges = 256
const MaxInputLength = 518

proc reachable(adjacency: ptr UncheckedArray[int], degree: ptr UncheckedArray[int],
    current: int, target: int64, visited: ptr UncheckedArray[bool]): bool =
  if int64(current) == target: return true
  visited[current] = true
  for position in 0 ..< degree[current]:
    let neighbor = adjacency[current * MaxVertices + position]
    if not visited[neighbor] and reachable(adjacency, degree, neighbor, target, visited): return true
  false

proc depth_first_search_recursive*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "depth_first_search_recursive".} =
  if input.isNil or length < 4 or length > csize_t(MaxInputLength): return -1
  let vertexCount = input[0]
  let edgeCountValue = input[1]
  let source = input[2]
  let target = input[3]
  if vertexCount < 1 or vertexCount > MaxVertices or edgeCountValue < 0
      or edgeCountValue > MaxEdges or source < 0 or source >= vertexCount: return -1
  let edgeCount = int(edgeCountValue)
  if int(length) != 4 + 2 * edgeCount: return -1
  for edge in 0 ..< edgeCount:
    let left = input[4 + 2 * edge]
    let right = input[5 + 2 * edge]
    if left < 0 or left >= vertexCount or right < 0 or right >= vertexCount: return -1

  var adjacency: array[MaxVertices * MaxVertices, int]
  var degree: array[MaxVertices, int]
  var seen: array[MaxVertices, uint64]
  for edge in 0 ..< edgeCount:
    let left = int(input[4 + 2 * edge])
    let right = int(input[5 + 2 * edge])
    let rightBit = 1'u64 shl right
    if (seen[left] and rightBit) == 0:
      seen[left] = seen[left] or rightBit
      adjacency[left * MaxVertices + degree[left]] = right
      inc degree[left]
    let leftBit = 1'u64 shl left
    if (seen[right] and leftBit) == 0:
      seen[right] = seen[right] or leftBit
      adjacency[right * MaxVertices + degree[right]] = left
      inc degree[right]
  var visited: array[MaxVertices, bool]
  if reachable(cast[ptr UncheckedArray[int]](addr adjacency[0]),
      cast[ptr UncheckedArray[int]](addr degree[0]), int(source), int64(target),
      cast[ptr UncheckedArray[bool]](addr visited[0])): return 1
  return 0
