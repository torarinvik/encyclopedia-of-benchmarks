const MaxN = 32
const MaxQ = 32
const MaxInput = 3 * MaxN + 2 * MaxQ

type Query = object
  left, right, id, block, rightKey, extra: int

proc less(a, b: Query): bool =
  if a.block != b.block: return a.block < b.block
  if a.rightKey != b.rightKey: return a.rightKey < b.rightKey
  a.id < b.id

proc siftDown(values: var array[MaxQ, Query], rootStart, endIndex: int) =
  var root = rootStart
  while root * 2 + 1 < endIndex:
    let child = root * 2 + 1
    var largest = root
    if less(values[largest], values[child]): largest = child
    if child + 1 < endIndex and less(values[largest], values[child + 1]): largest = child + 1
    if largest == root: return
    swap(values[root], values[largest])
    root = largest

proc heapSort(values: var array[MaxQ, Query], count: int) =
  var start = count div 2
  while start > 0:
    dec start
    siftDown(values, start, count)
  var finish = count
  while finish > 1:
    dec finish
    swap(values[0], values[finish])
    siftDown(values, 0, finish)

proc findRoot(parent: var array[MaxN, int], item: int): int =
  var node = item
  while parent[node] != node:
    parent[node] = parent[parent[node]]
    node = parent[node]
  node

proc lca(aRaw, bRaw: int, parent, depth: array[MaxN, int]): int =
  var a = aRaw
  var b = bRaw
  while depth[a] > depth[b]: a = parent[a]
  while depth[b] > depth[a]: b = parent[b]
  while a != b:
    a = parent[a]
    b = parent[b]
  a

proc toggle(vertex: int, colorId: array[MaxN, int],
    counts: var array[MaxN, int], active: var array[MaxN, bool], distinct: var int) =
  let color = colorId[vertex]
  if active[vertex]:
    active[vertex] = false
    dec counts[color]
    if counts[color] == 0: dec distinct
  else:
    active[vertex] = true
    if counts[color] == 0: inc distinct
    inc counts[color]

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc tree_path_distinct_mo*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tree_path_distinct_mo".} =
  if input == nil or length < 3 or length > csize_t(MaxInput + 1): return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN or qValue < 0 or qValue > MaxQ: return -1
  let n = int(nValue)
  let q = int(qValue)
  if int(length) != 3 * n + 2 * q: return -1

  var colors: array[MaxN, int64]
  for vertex in 0 ..< n: colors[vertex] = input[2 + vertex]
  var adjacent: array[MaxN, array[MaxN, bool]]
  var dsuParent, dsuSize: array[MaxN, int]
  for vertex in 0 ..< n:
    dsuParent[vertex] = vertex
    dsuSize[vertex] = 1
  var offset = 2 + n
  for _ in 0 ..< n - 1:
    let uValue = input[offset]
    let vValue = input[offset + 1]
    offset += 2
    if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue or uValue == vValue:
      return -1
    let u = int(uValue)
    let v = int(vValue)
    var rootU = findRoot(dsuParent, u)
    var rootV = findRoot(dsuParent, v)
    if rootU == rootV: return -1
    if dsuSize[rootU] < dsuSize[rootV]: swap(rootU, rootV)
    dsuParent[rootV] = rootU
    dsuSize[rootU] += dsuSize[rootV]
    adjacent[u][v] = true
    adjacent[v][u] = true

  var queryU, queryV: array[MaxQ, int]
  for id in 0 ..< q:
    let uValue = input[offset]
    let vValue = input[offset + 1]
    offset += 2
    if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue: return -1
    queryU[id] = int(uValue)
    queryV[id] = int(vValue)

  var colorId, firstColor: array[MaxN, int]
  var colorCount = 0
  for vertex in 0 ..< n:
    var rank = 0
    while rank < colorCount and colors[firstColor[rank]] != colors[vertex]: inc rank
    if rank == colorCount:
      firstColor[colorCount] = vertex
      inc colorCount
    colorId[vertex] = rank

  var parent, depth, entry, leave: array[MaxN, int]
  var euler: array[2 * MaxN, int]
  var eventNode, eventParent: array[2 * MaxN, int]
  var eventExit: array[2 * MaxN, bool]
  var top = 1
  var clock = 0
  eventNode[0] = 0
  eventParent[0] = n
  while top > 0:
    dec top
    let u = eventNode[top]
    let previous = eventParent[top]
    if eventExit[top]:
      leave[u] = clock
      euler[clock] = u
      inc clock
    else:
      parent[u] = previous
      entry[u] = clock
      euler[clock] = u
      inc clock
      eventNode[top] = u
      eventParent[top] = previous
      eventExit[top] = true
      inc top
      for step in 0 ..< n:
        let v = n - 1 - step
        if adjacent[u][v] and v != previous:
          depth[v] = depth[u] + 1
          eventNode[top] = v
          eventParent[top] = u
          eventExit[top] = false
          inc top
  var queries: array[MaxQ, Query]
  var blockSize = 1
  while (blockSize + 1) * (blockSize + 1) <= 2 * n: inc blockSize
  for id in 0 ..< q:
    var u = queryU[id]
    var v = queryV[id]
    if entry[u] > entry[v]: swap(u, v)
    let ancestor = lca(u, v, parent, depth)
    let left = if ancestor == u: entry[u] else: leave[u]
    let right = entry[v]
    let block = left div blockSize
    let rightKey = if block mod 2 == 0: right else: 2 * n - 1 - right
    let extra = if ancestor == u: -1 else: ancestor
    queries[id] = Query(left: left, right: right, id: id, block: block,
      rightKey: rightKey, extra: extra)
  heapSort(queries, q)

  var counts, answers: array[MaxN, int]
  var active: array[MaxN, bool]
  var distinct = 0
  var left = 0
  var right = -1
  for sortedIndex in 0 ..< q:
    let query = queries[sortedIndex]
    while left > query.left:
      dec left
      toggle(euler[left], colorId, counts, active, distinct)
    while right < query.right:
      inc right
      toggle(euler[right], colorId, counts, active, distinct)
    while left < query.left:
      toggle(euler[left], colorId, counts, active, distinct)
      inc left
    while right > query.right:
      toggle(euler[right], colorId, counts, active, distinct)
      dec right
    if query.extra >= 0:
      toggle(query.extra, colorId, counts, active, distinct)
      answers[query.id] = distinct
      toggle(query.extra, colorId, counts, active, distinct)
    else:
      answers[query.id] = distinct

  let required = 8 * q
  if output == nil or int(capacity) < required: return -2
  for id in 0 ..< q: storeLe(output, 8 * id, int64(answers[id]))
  int64(required)
