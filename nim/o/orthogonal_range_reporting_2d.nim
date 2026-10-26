const
  MaxPoints = 8
  MaxQueries = 8
  MaxInputLength = 50
  Base = 8
  MaxOutputWords = 73

type
  TreeIds = array[2 * Base, array[MaxPoints, int]]
  TreeSizes = array[2 * Base, int]

proc lowerX(order: array[MaxPoints, int], n: int, xs: array[MaxPoints, int64], bound: int64): int =
  var low = 0
  var high = n
  while low < high:
    let middle = low + (high - low) div 2
    if xs[order[middle]] < bound: low = middle + 1
    else: high = middle
  low

proc upperX(order: array[MaxPoints, int], n: int, xs: array[MaxPoints, int64], bound: int64): int =
  var low = 0
  var high = n
  while low < high:
    let middle = low + (high - low) div 2
    if xs[order[middle]] <= bound: low = middle + 1
    else: high = middle
  low

proc reportNode(node: int, treeIds: TreeIds, treeSize: TreeSizes,
    ys: array[MaxPoints, int64], yLow, yHigh: int64,
    hits: var array[MaxPoints, int], offset: int): int =
  var low = 0
  var high = treeSize[node]
  while low < high:
    let middle = low + (high - low) div 2
    if ys[treeIds[node][middle]] < yLow: low = middle + 1
    else: high = middle
  let first = low
  high = treeSize[node]
  while low < high:
    let middle = low + (high - low) div 2
    if ys[treeIds[node][middle]] <= yHigh: low = middle + 1
    else: high = middle
  for index in first ..< low:
    hits[offset + index - first] = treeIds[node][index]
  low - first

proc orthogonal_range_reporting_2d*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "orthogonal_range_reporting_2d".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > MaxPoints or input[1] < 1 or input[1] > MaxQueries: return -1
  let n = int(input[0])
  let q = int(input[1])
  if length != csize_t(2 + 2 * n + 4 * q): return -1

  var xs: array[MaxPoints, int64]
  var ys: array[MaxPoints, int64]
  for point in 0 ..< n:
    xs[point] = input[2 + 2 * point]
    ys[point] = input[3 + 2 * point]
    if xs[point] < 0 or xs[point] > 15 or ys[point] < 0 or ys[point] > 15: return -1
    for earlier in 0 ..< point:
      if xs[earlier] == xs[point] and ys[earlier] == ys[point]: return -1

  var queries: array[MaxQueries, array[4, int64]]
  let queryStart = 2 + 2 * n
  for query in 0 ..< q:
    for item in 0 ..< 4: queries[query][item] = input[queryStart + 4 * query + item]
    if queries[query][0] < 0 or queries[query][0] > queries[query][1] or queries[query][1] > 15 or
        queries[query][2] < 0 or queries[query][2] > queries[query][3] or queries[query][3] > 15: return -1

  var order: array[MaxPoints, int]
  for point in 0 ..< n: order[point] = point
  for index in 1 ..< n:
    let item = order[index]
    var position = index
    while position > 0:
      let previous = order[position - 1]
      let before = xs[item] < xs[previous] or
        (xs[item] == xs[previous] and (ys[item] < ys[previous] or
          (ys[item] == ys[previous] and item < previous)))
      if not before: break
      order[position] = previous
      dec position
    order[position] = item

  var treeIds: TreeIds
  var treeSize: TreeSizes
  for rank in 0 ..< n:
    treeIds[Base + rank][0] = order[rank]
    treeSize[Base + rank] = 1
  for node in countdown(Base - 1, 1):
    var left = 0
    var right = 0
    let leftNode = node * 2
    let rightNode = node * 2 + 1
    while left < treeSize[leftNode] or right < treeSize[rightNode]:
      var takeLeft = right >= treeSize[rightNode]
      if not takeLeft and left < treeSize[leftNode]:
        let leftId = treeIds[leftNode][left]
        let rightId = treeIds[rightNode][right]
        takeLeft = ys[leftId] < ys[rightId] or (ys[leftId] == ys[rightId] and leftId < rightId)
      var chosen: int
      if takeLeft:
        chosen = treeIds[leftNode][left]
        inc left
      else:
        chosen = treeIds[rightNode][right]
        inc right
      treeIds[node][treeSize[node]] = chosen
      inc treeSize[node]

  var words: array[MaxOutputWords, int64]
  var cursor = 0
  words[cursor] = int64(q)
  inc cursor
  for query in 0 ..< q:
    var left = lowerX(order, n, xs, queries[query][0]) + Base
    var right = upperX(order, n, xs, queries[query][1]) + Base
    var hits: array[MaxPoints, int]
    var hitCount = 0
    while left < right:
      if (left and 1) != 0:
        hitCount += reportNode(left, treeIds, treeSize, ys, queries[query][2], queries[query][3], hits, hitCount)
        inc left
      if (right and 1) != 0:
        dec right
        hitCount += reportNode(right, treeIds, treeSize, ys, queries[query][2], queries[query][3], hits, hitCount)
      left = left div 2
      right = right div 2
    for index in 1 ..< hitCount:
      let item = hits[index]
      var position = index
      while position > 0 and hits[position - 1] > item:
        hits[position] = hits[position - 1]
        dec position
      hits[position] = item
    words[cursor] = int64(hitCount)
    inc cursor
    for index in 0 ..< hitCount:
      words[cursor] = int64(hits[index])
      inc cursor

  let outputBytes = csize_t(8 * cursor)
  if output == nil or capacity < outputBytes: return -2
  for word in 0 ..< cursor:
    let bits = cast[uint64](words[word])
    for byte in 0 ..< 8:
      output[word * 8 + byte] = uint8((bits shr (8 * byte)) and 255)
  int64(outputBytes)
