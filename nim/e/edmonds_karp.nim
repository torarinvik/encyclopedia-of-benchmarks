const MaxVertices = 16
const MaxCapacity = 1_000_000'i64

proc edmonds_karp*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "edmonds_karp".} =
  if input.isNil or length < 3: return -1
  let n64 = input[0]
  let source64 = input[1]
  let sink64 = input[2]
  if n64 < 1 or n64 > MaxVertices or source64 < 0 or source64 >= n64 or sink64 < 0 or sink64 >= n64: return -1
  let n = int(n64)
  if length != csize_t(3 + n * n): return -1

  var residual: array[MaxVertices * MaxVertices, int64]
  for row in 0 ..< n:
    for column in 0 ..< n:
      let capacity = input[3 + row * n + column]
      if capacity < 0 or capacity > MaxCapacity or (row == column and capacity != 0): return -1
      residual[row * n + column] = capacity
  for left in 0 ..< n:
    for right in left + 1 ..< n:
      if residual[left * n + right] > 0 and residual[right * n + left] > 0: return -1

  let source = int(source64)
  let sink = int(sink64)
  if source == sink: return 0
  var totalFlow = 0'i64
  while true:
    var parent: array[MaxVertices, int]
    var queue: array[MaxVertices, int]
    for vertex in 0 ..< n: parent[vertex] = -1
    parent[source] = source
    var head = 0
    var tail = 1
    queue[0] = source
    while head < tail and parent[sink] == -1:
      let node = queue[head]
      inc head
      for neighbor in 0 ..< n:
        if residual[node * n + neighbor] <= 0 or parent[neighbor] != -1: continue
        parent[neighbor] = node
        if neighbor == sink: break
        queue[tail] = neighbor
        inc tail
    if parent[sink] == -1: return totalFlow
    var pathFlow = MaxCapacity
    var node = sink
    while node != source:
      let previous = parent[node]
      pathFlow = min(pathFlow, residual[previous * n + node])
      node = previous
    node = sink
    while node != source:
      let previous = parent[node]
      residual[previous * n + node] -= pathFlow
      residual[node * n + previous] += pathFlow
      node = previous
    totalFlow += pathFlow
