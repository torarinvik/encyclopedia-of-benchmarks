const
  MaxVertices = 40
  MaxEdgeWeight = 999'i64

proc edgeWeight(input: ptr UncheckedArray[int64], left, right: int): int64 =
  if left == right: return -1
  let row = max(left, right)
  let column = min(left, right)
  input[1 + row * (row - 1) div 2 + column]

proc problem107*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "problem107".} =
  if input == nil or length < 1: return -1
  let vertexCountValue = input[0]
  if vertexCountValue < 1 or vertexCountValue > MaxVertices: return -1
  let vertexCount = int(vertexCountValue)
  if length != csize_t(1 + vertexCount * (vertexCount - 1) div 2): return -1

  var totalWeight: int64 = 0
  for index in 1..<int(length):
    if input[index] < -1 or input[index] > MaxEdgeWeight: return -1
    if input[index] >= 0: totalWeight += input[index]

  var selected: array[MaxVertices, bool]
  var bestWeight: array[MaxVertices, int64]
  for vertex in 0..<vertexCount: bestWeight[vertex] = MaxEdgeWeight + 1
  bestWeight[0] = 0
  var treeWeight: int64 = 0
  for iteration in 0..<vertexCount:
    var nextVertex = vertexCount
    var nextWeight = MaxEdgeWeight + 1
    for vertex in 0..<vertexCount:
      if not selected[vertex] and bestWeight[vertex] < nextWeight:
        nextVertex = vertex
        nextWeight = bestWeight[vertex]
    if nextVertex == vertexCount: return -1
    selected[nextVertex] = true
    treeWeight += nextWeight
    for vertex in 0..<vertexCount:
      if selected[vertex]: continue
      let weight = edgeWeight(input, nextVertex, vertex)
      if weight >= 0 and weight < bestWeight[vertex]: bestWeight[vertex] = weight
  totalWeight - treeWeight
