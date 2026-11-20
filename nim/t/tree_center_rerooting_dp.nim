const MaxN = 64
const MaxInputLength = 1 + 2 * (MaxN - 1)

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc tree_center_rerooting_dp*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tree_center_rerooting_dp".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  if length != csize_t(1 + 2 * (n - 1)): return -1

  var adjacency: array[MaxN * MaxN, int]
  var degree: array[MaxN, int]
  for edge in 0 ..< (n - 1):
    let offset = 1 + 2 * edge
    let leftValue = input[offset]
    let rightValue = input[offset + 1]
    if leftValue < 0 or leftValue >= nValue or rightValue < 0 or
       rightValue >= nValue or leftValue == rightValue: return -1
    let left = int(leftValue)
    let right = int(rightValue)
    adjacency[left * MaxN + degree[left]] = right
    inc degree[left]
    adjacency[right * MaxN + degree[right]] = left
    inc degree[right]

  var parent: array[MaxN, int]
  var order: array[MaxN, int]
  for vertex in 0 ..< n: parent[vertex] = MaxN
  parent[0] = MaxN + 1
  order[0] = 0
  var orderCount = 1
  var position = 0
  while position < orderCount:
    let vertex = order[position]
    for edge in 0 ..< degree[vertex]:
      let child = adjacency[vertex * MaxN + edge]
      if child == parent[vertex]: continue
      if parent[child] != MaxN: return -1
      parent[child] = vertex
      order[orderCount] = child
      inc orderCount
    inc position
  if orderCount != n: return -1

  var down, best, second: array[MaxN, int]
  var bestChild: array[MaxN, int]
  for vertex in 0 ..< n: bestChild[vertex] = MaxN
  for position in countdown(n - 1, 0):
    let vertex = order[position]
    for edge in 0 ..< degree[vertex]:
      let child = adjacency[vertex * MaxN + edge]
      if parent[child] != vertex: continue
      let branch = down[child] + 1
      if branch > best[vertex]:
        second[vertex] = best[vertex]
        best[vertex] = branch
        bestChild[vertex] = child
      elif branch > second[vertex]:
        second[vertex] = branch
    down[vertex] = best[vertex]

  var outside: array[MaxN, int]
  for vertex in 0 ..< n: outside[vertex] = -1
  for i in 0 ..< n:
    let vertex = order[i]
    for edge in 0 ..< degree[vertex]:
      let child = adjacency[vertex * MaxN + edge]
      if parent[child] != vertex: continue
      let sibling = if bestChild[vertex] == child: second[vertex] else: best[vertex]
      outside[child] = max(outside[vertex], sibling) + 1

  var radius = MaxN
  for vertex in 0 ..< n:
    radius = min(radius, max(down[vertex], outside[vertex]))
  var centers: array[2, int64]
  var centerCount = 0
  for vertex in 0 ..< n:
    if max(down[vertex], outside[vertex]) == radius:
      centers[centerCount] = int64(vertex)
      inc centerCount
  let required = 8 * centerCount
  if output.isNil or capacity < csize_t(required): return -2
  for i in 0 ..< centerCount: storeI64Le(output, 8 * i, centers[i])
  int64(required)
