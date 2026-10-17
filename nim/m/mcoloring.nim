const
  MaxVertices = 14
  MaxParseableInputLength = 17

proc findRoot(parent: var array[MaxVertices, int], vertexInput: int): int =
  var vertex = vertexInput
  while parent[vertex] != vertex:
    parent[vertex] = parent[parent[vertex]]
    vertex = parent[vertex]
  vertex

proc mcoloring*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "mcoloring".} =
  if input == nil or length < 2 or length > MaxParseableInputLength.csize_t:
    return -1
  let nValue = input[0]
  let colorsValue = input[1]
  if nValue < 0 or nValue > MaxVertices.int64 or colorsValue < 1 or colorsValue > MaxVertices.int64:
    return -1
  let n = int(nValue)
  if length != (n + 2).csize_t:
    return -1

  var masks: array[MaxVertices, uint32]
  var parent: array[MaxVertices, int]
  let validMask = if n == 0: 0'u32 else: (1'u32 shl n) - 1'u32
  for vertex in 0 ..< n:
    let raw = input[vertex + 2]
    if raw < 0 or uint64(raw) > uint64(validMask):
      return -1
    masks[vertex] = uint32(raw)
    if (masks[vertex] and (1'u32 shl vertex)) != 0:
      return -1
    parent[vertex] = vertex
  for vertex in 0 ..< n:
    for neighbor in vertex + 1 ..< n:
      let edge = (masks[vertex] and (1'u32 shl neighbor)) != 0
      if edge != ((masks[neighbor] and (1'u32 shl vertex)) != 0):
        return -1
      if edge:
        let rootA = findRoot(parent, vertex)
        let rootB = findRoot(parent, neighbor)
        if rootA == rootB:
          return -1
        parent[rootA] = rootB

  var colors: array[MaxVertices, int] # Zero initialization is overwritten below.
  var visited: array[MaxVertices, bool]
  var queue: array[MaxVertices, int]
  for vertex in 0 ..< n:
    colors[vertex] = 1
  var maximumColor = 1
  for start in 0 ..< n:
    if visited[start]:
      continue
    var head = 0
    var tail = 0
    visited[start] = true
    queue[tail] = start
    inc tail
    while head < tail:
      let vertex = queue[head]
      inc head
      for neighbor in 0 ..< n:
        if (masks[vertex] and (1'u32 shl neighbor)) == 0:
          continue
        if colors[vertex] == colors[neighbor]:
          inc colors[neighbor]
        maximumColor = max(maximumColor, max(colors[vertex], colors[neighbor]))
        if maximumColor > int(colorsValue):
          return 0
        if not visited[neighbor]:
          visited[neighbor] = true
          queue[tail] = neighbor
          inc tail
  return 1
