const MaxN = 16
const MaxInputValues = 257
const MaxWeight = 1_000_000'i64

proc stoer_wagner*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "stoer_wagner".} =
  if input == nil or length < 1 or length > csize_t(MaxInputValues): return -1
  let nValue = input[0]
  if nValue < 2 or nValue > MaxN: return -1
  let n = int(nValue)
  if length != csize_t(1 + n * n): return -1

  var graph: array[MaxN * MaxN, int64]
  for row in 0 ..< n:
    for column in 0 ..< n:
      let weight = input[1 + row * n + column]
      if weight < 0 or weight > MaxWeight: return -1
      graph[row * MaxN + column] = weight
  for row in 0 ..< n:
    if graph[row * MaxN + row] != 0: return -1
    for column in row + 1 ..< n:
      if graph[row * MaxN + column] != graph[column * MaxN + row]: return -1

  var merged: array[MaxN, bool]
  var minCut = 120_000_001'i64
  for phase in 0 ..< (n - 1):
    var inSet: array[MaxN, bool]
    var weights: array[MaxN, int64]
    var previous = -1
    var last = -1
    for _ in 0 ..< (n - phase):
      var current = -1
      var maxWeight = -1'i64
      for vertex in 0 ..< n:
        if not merged[vertex] and not inSet[vertex] and weights[vertex] > maxWeight:
          maxWeight = weights[vertex]
          current = vertex
      if current < 0: break
      inSet[current] = true
      previous = last
      last = current
      for vertex in 0 ..< n:
        if not merged[vertex] and not inSet[vertex]:
          weights[vertex] += graph[current * MaxN + vertex]
    if last < 0 or previous < 0: return -1
    if weights[last] < minCut: minCut = weights[last]
    for vertex in 0 ..< n:
      graph[previous * MaxN + vertex] += graph[last * MaxN + vertex]
      graph[vertex * MaxN + previous] = graph[previous * MaxN + vertex]
    merged[last] = true
  minCut
