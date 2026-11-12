const MaxN = 8
const MaxM = 20

proc findRoot(parent: var array[MaxN, int], start: int): int =
  var vertex = start
  while parent[vertex] != vertex:
    parent[vertex] = parent[parent[vertex]]
    vertex = parent[vertex]
  vertex

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc second_best_mst*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "second_best_mst".} =
  if input.isNil or length < 2 or length > csize_t(2 + 3 * MaxM): return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 1 or nValue > int64(MaxN) or mValue < nValue - 1 or mValue > int64(MaxM): return -1
  let n = int(nValue)
  let m = int(mValue)
  if length != csize_t(2 + 3 * m): return -1

  var edgeU: array[MaxM, int]
  var edgeV: array[MaxM, int]
  var edgeWeight: array[MaxM, int64]
  var order: array[MaxM, int]
  var seen: array[MaxN, array[MaxN, bool]]
  for edge in 0 ..< m:
    let uValue = input[2 + 3 * edge]
    let vValue = input[3 + 3 * edge]
    let weight = input[4 + 3 * edge]
    if uValue < 0 or uValue >= vValue or vValue >= nValue or weight < 0 or weight > 1_000_000: return -1
    let u = int(uValue)
    let v = int(vValue)
    if seen[u][v]: return -1
    seen[u][v] = true
    edgeU[edge] = u
    edgeV[edge] = v
    edgeWeight[edge] = weight
    order[edge] = edge

  for i in 1 ..< m:
    let edge = order[i]
    var j = i
    while j > 0 and (edgeWeight[order[j - 1]] > edgeWeight[edge] or
        (edgeWeight[order[j - 1]] == edgeWeight[edge] and order[j - 1] > edge)):
      order[j] = order[j - 1]
      dec j
    order[j] = edge

  var dsu: array[MaxN, int]
  var componentSize: array[MaxN, int]
  for vertex in 0 ..< n:
    dsu[vertex] = vertex
    componentSize[vertex] = 1
  var inMst: array[MaxM, bool]
  var treeTo: array[MaxN, array[MaxN, int]]
  var treeEdge: array[MaxN, array[MaxN, int]]
  var degree: array[MaxN, int]
  var selected = 0
  var mstWeight = 0'i64
  for position in 0 ..< m:
    let edge = order[position]
    var rootU = findRoot(dsu, edgeU[edge])
    var rootV = findRoot(dsu, edgeV[edge])
    if rootU == rootV: continue
    if componentSize[rootU] < componentSize[rootV]: swap(rootU, rootV)
    dsu[rootV] = rootU
    componentSize[rootU] += componentSize[rootV]
    inMst[edge] = true
    inc selected
    mstWeight += edgeWeight[edge]
    treeTo[edgeU[edge]][degree[edgeU[edge]]] = edgeV[edge]
    treeEdge[edgeU[edge]][degree[edgeU[edge]]] = edge
    inc degree[edgeU[edge]]
    treeTo[edgeV[edge]][degree[edgeV[edge]]] = edgeU[edge]
    treeEdge[edgeV[edge]][degree[edgeV[edge]]] = edge
    inc degree[edgeV[edge]]
  if selected != n - 1: return -1

  var secondWeight = -1'i64
  var enteringEdge = -1
  var leavingEdge = -1
  for added in 0 ..< m:
    if inMst[added]: continue
    var parent: array[MaxN, int]
    var parentEdge: array[MaxN, int]
    var queue: array[MaxN, int]
    for vertex in 0 ..< n: parent[vertex] = -1
    var head = 0
    var tail = 0
    let start = edgeU[added]
    let target = edgeV[added]
    parent[start] = start
    queue[tail] = start
    inc tail
    while head < tail and parent[target] == -1:
      let vertex = queue[head]
      inc head
      for i in 0 ..< degree[vertex]:
        let next = treeTo[vertex][i]
        if parent[next] != -1: continue
        parent[next] = vertex
        parentEdge[next] = treeEdge[vertex][i]
        queue[tail] = next
        inc tail
    var firstWeight = -1'i64
    var secondPathWeight = -1'i64
    var firstEdge = -1
    var secondPathEdge = -1
    var vertex = target
    while vertex != start:
      let pathEdge = parentEdge[vertex]
      let weight = edgeWeight[pathEdge]
      if weight > firstWeight:
        secondPathWeight = firstWeight
        secondPathEdge = firstEdge
        firstWeight = weight
        firstEdge = pathEdge
      elif weight == firstWeight:
        if firstEdge < 0 or pathEdge < firstEdge: firstEdge = pathEdge
      elif weight > secondPathWeight:
        secondPathWeight = weight
        secondPathEdge = pathEdge
      elif weight == secondPathWeight and (secondPathEdge < 0 or pathEdge < secondPathEdge):
        secondPathEdge = pathEdge
      vertex = parent[vertex]
    var removedWeight = -1'i64
    var removedEdge = -1
    if edgeWeight[added] > firstWeight:
      removedWeight = firstWeight
      removedEdge = firstEdge
    elif edgeWeight[added] == firstWeight and secondPathWeight >= 0:
      removedWeight = secondPathWeight
      removedEdge = secondPathEdge
    if removedEdge < 0: continue
    let candidate = mstWeight + edgeWeight[added] - removedWeight
    if secondWeight < 0 or candidate < secondWeight or
        (candidate == secondWeight and (added < enteringEdge or
        (added == enteringEdge and removedEdge < leavingEdge))):
      secondWeight = candidate
      enteringEdge = added
      leavingEdge = removedEdge

  if output.isNil or capacity < 32: return -2
  storeI64Le(output, 0, mstWeight)
  storeI64Le(output, 8, secondWeight)
  storeI64Le(output, 16, int64(enteringEdge))
  storeI64Le(output, 24, int64(leavingEdge))
  32
