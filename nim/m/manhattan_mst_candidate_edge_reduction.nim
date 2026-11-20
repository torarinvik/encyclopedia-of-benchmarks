const
  MaxN = 31
  MaxCandidates = 124
  MaxParseableInput = 64
  FenwickSize = 32

proc mmFenwickAdd(tree: var array[FenwickSize, int64], n, indexInput: int,
    delta: int64) =
  var index = indexInput + 1
  while index <= n:
    tree[index] += delta
    index += index and -index

proc mmFenwickSum(tree: array[FenwickSize, int64], countInput: int): int64 =
  var index = countInput
  var total = 0'i64
  while index > 0:
    total += tree[index]
    index -= (index and -index)
  return total

proc mmFenwickSelect(tree: array[FenwickSize, int64], n: int,
    kthInput: int64): int =
  var index = 0
  var bit = 1
  while bit * 2 <= n: bit *= 2
  var kth = kthInput
  while bit > 0:
    let next = index + bit
    if next <= n and tree[next] < kth:
      kth -= tree[next]
      index = next
    bit = bit div 2
  return index

proc mmFind(parent: var array[MaxN, int], nodeInput: int): int =
  var root = nodeInput
  while parent[root] != root: root = parent[root]
  var current = nodeInput
  while parent[current] != current:
    let next = parent[current]
    parent[current] = root
    current = next
  return root

proc mmUnion(parent: var array[MaxN, int],
    componentSize: var array[MaxN, int], left, right: int): bool =
  let rootLeft = mmFind(parent, left)
  let rootRight = mmFind(parent, right)
  if rootLeft == rootRight: return false
  if componentSize[rootLeft] < componentSize[rootRight]:
    parent[rootLeft] = rootRight
    componentSize[rootRight] += componentSize[rootLeft]
  else:
    parent[rootRight] = rootLeft
    componentSize[rootLeft] += componentSize[rootRight]
  return true

proc mmAddEdge(edgeU: var array[MaxCandidates, int],
    edgeV: var array[MaxCandidates, int],
    edgeWeight: var array[MaxCandidates, int64], edgeCount: var int,
    first, second: int, x: array[MaxN, int64], y: array[MaxN, int64]) =
  var u = first
  var v = second
  if u > v: swap(u, v)
  var dx = x[first] - x[second]
  var dy = y[first] - y[second]
  if dx < 0: dx = -dx
  if dy < 0: dy = -dy
  edgeU[edgeCount] = u
  edgeV[edgeCount] = v
  edgeWeight[edgeCount] = dx + dy
  inc edgeCount

proc mmSiftPoints(order: var array[MaxN, int], keys: openArray[int64],
    heapSize, rootInput: int) =
  var root = rootInput
  while root * 2 + 1 < heapSize:
    let left = root * 2 + 1
    var largest = root
    let leftPoint = order[left]
    let largestPoint = order[largest]
    if keys[leftPoint] > keys[largestPoint] or
        (keys[leftPoint] == keys[largestPoint] and leftPoint > largestPoint):
      largest = left
    let right = left + 1
    if right < heapSize:
      let rightPoint = order[right]
      let currentLargestPoint = order[largest]
      if keys[rightPoint] > keys[currentLargestPoint] or
          (keys[rightPoint] == keys[currentLargestPoint] and rightPoint > currentLargestPoint):
        largest = right
    if largest == root: break
    swap(order[root], order[largest])
    root = largest

proc mmSortPoints(order: var array[MaxN, int], keys: openArray[int64], size: int) =
  if size < 2: return
  var start = size div 2
  while start > 0:
    dec start
    mmSiftPoints(order, keys, size, start)
  var finish = size
  while finish > 1:
    dec finish
    swap(order[0], order[finish])
    mmSiftPoints(order, keys, finish, 0)

proc mmSiftEdges(edgeU: var array[MaxCandidates, int],
    edgeV: var array[MaxCandidates, int],
    edgeWeight: var array[MaxCandidates, int64], heapSize, rootInput: int) =
  var root = rootInput
  while root * 2 + 1 < heapSize:
    let left = root * 2 + 1
    var largest = root
    if edgeWeight[largest] < edgeWeight[left] or
        (edgeWeight[largest] == edgeWeight[left] and edgeU[largest] < edgeU[left]) or
        (edgeWeight[largest] == edgeWeight[left] and edgeU[largest] == edgeU[left] and edgeV[largest] < edgeV[left]):
      largest = left
    let right = left + 1
    if right < heapSize:
      if edgeWeight[largest] < edgeWeight[right] or
          (edgeWeight[largest] == edgeWeight[right] and edgeU[largest] < edgeU[right]) or
          (edgeWeight[largest] == edgeWeight[right] and edgeU[largest] == edgeU[right] and edgeV[largest] < edgeV[right]):
        largest = right
    if largest == root: break
    swap(edgeU[root], edgeU[largest])
    swap(edgeV[root], edgeV[largest])
    swap(edgeWeight[root], edgeWeight[largest])
    root = largest

proc mmSortEdges(edgeU: var array[MaxCandidates, int],
    edgeV: var array[MaxCandidates, int],
    edgeWeight: var array[MaxCandidates, int64], size: int) =
  if size < 2: return
  var start = size div 2
  while start > 0:
    dec start
    mmSiftEdges(edgeU, edgeV, edgeWeight, size, start)
  var finish = size
  while finish > 1:
    dec finish
    swap(edgeU[0], edgeU[finish])
    swap(edgeV[0], edgeV[finish])
    swap(edgeWeight[0], edgeWeight[finish])
    mmSiftEdges(edgeU, edgeV, edgeWeight, finish, 0)

proc manhattanMstCandidateEdgeReduction*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "manhattan_mst_candidate_edge_reduction".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxParseableInput): return -1
  let nValue = input[0]
  if nValue < 0 or nValue > MaxN: return -1
  let n = int(nValue)
  if length != csize_t(1 + 2 * n): return -1

  var x: array[MaxN, int64]
  var y: array[MaxN, int64]
  for point in 0 ..< n:
    let xValue = input[1 + 2 * point]
    let yValue = input[2 + 2 * point]
    if xValue < -1000 or xValue > 1000 or yValue < -1000 or yValue > 1000: return -1
    x[point] = xValue
    y[point] = yValue
  if n < 2: return 0

  var order: array[MaxN, int]
  var byX: array[MaxN, int]
  var sortKey: array[MaxN, int64]
  var rankOf: array[MaxN, int]
  var idAtRank: array[MaxN, int]
  var fenwick: array[FenwickSize, int64]
  var edgeU: array[MaxCandidates, int]
  var edgeV: array[MaxCandidates, int]
  var edgeWeight: array[MaxCandidates, int64]
  var edgeCount = 0

  for point in 0 ..< n:
    order[point] = point
    sortKey[point] = x[point]
  mmSortPoints(order, sortKey, n)
  for index in 1 ..< n:
    if x[order[index - 1]] == x[order[index]]: return -1
  for point in 0 ..< n: sortKey[point] = y[point]
  mmSortPoints(order, sortKey, n)
  for index in 1 ..< n:
    if y[order[index - 1]] == y[order[index]]: return -1

  for direction in 0 ..< 4:
    for point in 0 ..< n:
      order[point] = point
      byX[point] = point
    for point in 0 ..< n: sortKey[point] = x[point] + y[point]
    mmSortPoints(order, sortKey, n)
    for point in 0 ..< n: sortKey[point] = x[point]
    mmSortPoints(byX, sortKey, n)
    for rank in 0 ..< n:
      let point = byX[rank]
      rankOf[point] = rank
      idAtRank[rank] = point
    for index in 0 .. FenwickSize - 1: fenwick[index] = 0

    for position in 0 ..< n:
      let current = order[position]
      let currentRank = rankOf[current]
      var activeCount = mmFenwickSum(fenwick, currentRank + 1)
      while activeCount > 0:
        let candidateRank = mmFenwickSelect(fenwick, n, activeCount)
        let candidate = idAtRank[candidateRank]
        if x[current] - y[current] > x[candidate] - y[candidate]: break
        mmAddEdge(edgeU, edgeV, edgeWeight, edgeCount, current, candidate, x, y)
        mmFenwickAdd(fenwick, n, candidateRank, -1)
        activeCount = mmFenwickSum(fenwick, currentRank + 1)
      mmFenwickAdd(fenwick, n, currentRank, 1)

    if direction mod 2 == 0:
      for point in 0 ..< n: swap(x[point], y[point])
    else:
      for point in 0 ..< n: x[point] = -x[point]

  mmSortEdges(edgeU, edgeV, edgeWeight, edgeCount)

  var parent: array[MaxN, int]
  var componentSize: array[MaxN, int]
  for point in 0 ..< n:
    parent[point] = point
    componentSize[point] = 1
  var components = n
  var total = 0'i64
  for edge in 0 ..< edgeCount:
    if mmUnion(parent, componentSize, edgeU[edge], edgeV[edge]):
      total += edgeWeight[edge]
      dec components
      if components == 1: break
  if components != 1: return -1
  return total
