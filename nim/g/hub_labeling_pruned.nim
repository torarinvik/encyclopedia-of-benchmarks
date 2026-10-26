const
  MaxVertices = 8
  MaxEdges = 28
  MaxInput = 66
  MaxFields = 73
  MaxOutputBytes = 8 * MaxFields

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc uniqueShortestPaths(adjacency: array[MaxVertices * MaxVertices, bool], n: int): bool =
  for source in 0 ..< n:
    var distance: array[MaxVertices, int]
    var ways: array[MaxVertices, uint8]
    var queue: array[MaxVertices, int]
    for i in 0 ..< n: distance[i] = -1
    var head = 0
    var tail = 0
    distance[source] = 0; ways[source] = 1; queue[tail] = source; inc tail
    while head < tail:
      let vertex = queue[head]; inc head
      for neighbor in 0 ..< n:
        if not adjacency[vertex * MaxVertices + neighbor]: continue
        if distance[neighbor] < 0:
          distance[neighbor] = distance[vertex] + 1
          ways[neighbor] = ways[vertex]
          queue[tail] = neighbor; inc tail
        elif distance[neighbor] == distance[vertex] + 1:
          ways[neighbor] = min(2, int(ways[neighbor]) + int(ways[vertex])).uint8
    for vertex in 0 ..< n:
      if ways[vertex] != 1: return false
  true

proc hub_labeling_pruned*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "hub_labeling_pruned".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  if input[0] < 1 or input[0] > MaxVertices or input[1] < 0 or input[1] > MaxEdges: return -1
  let n = int(input[0])
  let m = int(input[1])
  if int(length) != 2 + n + 2 * m: return -1
  var seenOrder: array[MaxVertices, bool]
  for i in 0 ..< n:
    let vertex = input[2 + i]
    if vertex < 0 or vertex >= n or seenOrder[int(vertex)]: return -1
    seenOrder[int(vertex)] = true
  var adjacency: array[MaxVertices * MaxVertices, bool]
  var previousLeft = -1'i64
  var previousRight = -1'i64
  for edge in 0 ..< m:
    let left = input[2 + n + 2 * edge]
    let right = input[3 + n + 2 * edge]
    if left < 0 or right <= left or right >= n or left < previousLeft
        or (left == previousLeft and right <= previousRight): return -1
    previousLeft = left; previousRight = right
    adjacency[int(left) * MaxVertices + int(right)] = true
    adjacency[int(right) * MaxVertices + int(left)] = true
  if not uniqueShortestPaths(adjacency, n): return -1

  var labels: array[MaxVertices * MaxVertices, int16]
  for i in 0 ..< MaxVertices * MaxVertices: labels[i] = -1
  for orderIndex in 0 ..< n:
    let hub = int(input[2 + orderIndex])
    var distance: array[MaxVertices, int]
    var queue: array[MaxVertices, int]
    for i in 0 ..< n: distance[i] = -1
    var head = 0
    var tail = 0
    distance[hub] = 0; queue[tail] = hub; inc tail
    while head < tail:
      let vertex = queue[head]; inc head
      var estimate = 2 * MaxVertices
      for common in 0 ..< n:
        let fromHub = labels[hub * MaxVertices + common]
        let fromVertex = labels[vertex * MaxVertices + common]
        if fromHub >= 0 and fromVertex >= 0 and int(fromHub) + int(fromVertex) < estimate:
          estimate = int(fromHub) + int(fromVertex)
      if estimate <= distance[vertex]: continue
      labels[vertex * MaxVertices + hub] = int16(distance[vertex])
      for neighbor in 0 ..< n:
        if adjacency[vertex * MaxVertices + neighbor] and distance[neighbor] < 0:
          distance[neighbor] = distance[vertex] + 1
          queue[tail] = neighbor; inc tail

  var fields: array[MaxFields, int64]
  var fieldCount = 0
  fields[fieldCount] = int64(n); inc fieldCount
  for vertex in 0 ..< n:
    let countIndex = fieldCount; inc fieldCount
    var count = 0'i64
    for hub in 0 ..< n:
      let value = labels[vertex * MaxVertices + hub]
      if value >= 0:
        fields[fieldCount] = int64(hub) or (int64(value) shl 8)
        inc fieldCount; inc count
    fields[countIndex] = count
  let bytes = fieldCount * 8
  if output.isNil or capacity < csize_t(bytes): return -2
  var staged: array[MaxOutputBytes, uint8]
  for i in 0 ..< fieldCount: storeI64Le(cast[ptr UncheckedArray[uint8]](addr staged[0]), 8 * i, fields[i])
  for i in 0 ..< bytes: output[i] = staged[i]
  int64(bytes)
