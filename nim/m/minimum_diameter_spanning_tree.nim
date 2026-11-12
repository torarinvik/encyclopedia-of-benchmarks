import std/[algorithm]

const MaxN = 8
const MaxM = 20
const MaxInputValues = 2 + 3 * MaxM + 1
const Inf = 1_000_000_000_000'i64

proc shortestTree(n, m: int, edgeU, edgeV: array[MaxM, int],
    edgeWeight: array[MaxM, int64], centerKind, centerRoot: int,
    centerX2: int64, centerEdge: int, distance, parentEdge: var array[MaxN, int64]) =
  var settled: array[MaxN, bool]
  for vertex in 0 ..< n:
    distance[vertex] = Inf
    parentEdge[vertex] = -1
  if centerKind == 0:
    distance[centerRoot] = 0
  else:
    var u = edgeU[centerEdge]
    var v = edgeV[centerEdge]
    if u > v: swap(u, v)
    distance[u] = centerX2
    distance[v] = 2 * edgeWeight[centerEdge] - centerX2
  for _ in 0 ..< n:
    var current = n
    for vertex in 0 ..< n:
      if not settled[vertex] and (current == n or distance[vertex] < distance[current]):
        current = vertex
    if current == n or distance[current] == Inf: return
    settled[current] = true
    for edgeId in 0 ..< m:
      let left = edgeU[edgeId]
      let right = edgeV[edgeId]
      if left == right: continue
      var neighbor = n
      if current == left: neighbor = right
      elif current == right: neighbor = left
      else: continue
      let candidate = distance[current] + 2 * edgeWeight[edgeId]
      if not settled[neighbor] and candidate < distance[neighbor]:
        distance[neighbor] = candidate
        parentEdge[neighbor] = int64(edgeId)

proc selectedTreeDiameter(n: int, selected: array[MaxN, int],
    edgeU, edgeV: array[MaxM, int], edgeWeight: array[MaxM, int64]): int64 =
  var adjacent: array[MaxN, array[MaxN, bool]]
  var weight: array[MaxN, array[MaxN, int64]]
  for index in 0 ..< n - 1:
    let edgeId = selected[index]
    let u = edgeU[edgeId]
    let v = edgeV[edgeId]
    adjacent[u][v] = true
    adjacent[v][u] = true
    weight[u][v] = edgeWeight[edgeId]
    weight[v][u] = edgeWeight[edgeId]
  for source in 0 ..< n:
    var distance: array[MaxN, int64]
    var parent, stack: array[MaxN, int]
    for vertex in 0 ..< n:
      distance[vertex] = -1
      parent[vertex] = n
    var top = 1
    stack[0] = source
    distance[source] = 0
    while top > 0:
      dec top
      let current = stack[top]
      result = max(result, distance[current])
      for neighbor in 0 ..< n:
        if adjacent[current][neighbor] and parent[current] != neighbor and distance[neighbor] < 0:
          parent[neighbor] = current
          distance[neighbor] = distance[current] + weight[current][neighbor]
          stack[top] = neighbor
          inc top

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc minimum_diameter_spanning_tree*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "minimum_diameter_spanning_tree".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputValues): return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 1 or nValue > MaxN or mValue < 0 or mValue > MaxM: return -1
  let n = int(nValue)
  let m = int(mValue)
  if length != csize_t(2 + 3 * m): return -1

  var edgeU, edgeV: array[MaxM, int]
  var edgeWeight: array[MaxM, int64]
  var graphDistance: array[MaxN, array[MaxN, int64]]
  for left in 0 ..< n:
    for right in 0 ..< n:
      graphDistance[left][right] = if left == right: 0 else: Inf
  for edgeId in 0 ..< m:
    let offset = 2 + 3 * edgeId
    let uValue = input[offset]
    let vValue = input[offset + 1]
    let edgeW = input[offset + 2]
    if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue or edgeW < 0 or edgeW > 9:
      return -1
    let u = int(uValue)
    let v = int(vValue)
    edgeU[edgeId] = u
    edgeV[edgeId] = v
    edgeWeight[edgeId] = edgeW
    if u != v and edgeW < graphDistance[u][v]:
      graphDistance[u][v] = edgeW
      graphDistance[v][u] = edgeW
  for middle in 0 ..< n:
    for left in 0 ..< n:
      for right in 0 ..< n:
        graphDistance[left][right] = min(graphDistance[left][right],
          graphDistance[left][middle] + graphDistance[middle][right])
  for vertex in 0 ..< n:
    if graphDistance[0][vertex] == Inf: return -1

  var bestRadius2 = Inf
  var bestKind = 0
  var bestRoot = 0
  var bestEdge = 0
  var bestX2 = 0'i64
  for root in 0 ..< n:
    var eccentricity = 0'i64
    for vertex in 0 ..< n: eccentricity = max(eccentricity, graphDistance[root][vertex])
    let radius2 = 2 * eccentricity
    if radius2 < bestRadius2:
      bestRadius2 = radius2
      bestKind = 0
      bestRoot = root
  for edgeId in 0 ..< m:
    var u = edgeU[edgeId]
    var v = edgeV[edgeId]
    let edgeW = edgeWeight[edgeId]
    if u == v: continue
    if u > v: swap(u, v)
    for x2 in 0'i64 .. 2 * edgeW:
      var radius2 = 0'i64
      for vertex in 0 ..< n:
        let fromU = 2 * graphDistance[u][vertex] + x2
        let fromV = 2 * graphDistance[v][vertex] + 2 * edgeW - x2
        radius2 = max(radius2, min(fromU, fromV))
      if radius2 < bestRadius2:
        bestRadius2 = radius2
        bestKind = 1
        bestRoot = u
        bestX2 = x2
        bestEdge = edgeId

  var centerDistance, parentEdge: array[MaxN, int64]
  shortestTree(n, m, edgeU, edgeV, edgeWeight, bestKind, bestRoot,
    bestX2, bestEdge, centerDistance, parentEdge)
  var selected: array[MaxN, int]
  var selectedCount = 0
  for vertex in 0 ..< n:
    if parentEdge[vertex] >= 0:
      selected[selectedCount] = int(parentEdge[vertex])
      inc selectedCount
  if selectedCount + 2 == n and bestKind == 1:
    let u = edgeU[bestEdge]
    let v = edgeV[bestEdge]
    if parentEdge[u] == -1 and parentEdge[v] == -1:
      selected[selectedCount] = bestEdge
      inc selectedCount
  if selectedCount != n - 1: return -1
  for left in 0 ..< selectedCount:
    for right in left + 1 ..< selectedCount:
      if selected[right] < selected[left]: swap(selected[left], selected[right])

  var staged: array[MaxN, int64]
  staged[0] = selectedTreeDiameter(n, selected, edgeU, edgeV, edgeWeight)
  for index in 0 ..< selectedCount: staged[index + 1] = int64(selected[index])
  let required = 8 * n
  if output.isNil or capacity < csize_t(required): return -2
  for index in 0 ..< n: storeI64Le(output, 8 * index, staged[index])
  int64(required)
