import std/ffi

const
  MaxN = 16
  MaxNodes = 2 * MaxN - 1
  TreeSize = 4 * MaxN + 4
  MaxParseableLength = MaxN + 2

proc dctAdd(node, left, right, ql, qr, delta: int,
            minimum, lazy: var array[TreeSize, int]) =
  if ql <= left and right <= qr:
    minimum[node] += delta
    lazy[node] += delta
    return
  let middle = (left + right) div 2
  if lazy[node] != 0:
    let tag = lazy[node]
    minimum[node * 2] += tag
    minimum[node * 2 + 1] += tag
    lazy[node * 2] += tag
    lazy[node * 2 + 1] += tag
    lazy[node] = 0
  if ql <= middle and qr >= left:
    dctAdd(node * 2, left, middle, ql, qr, delta, minimum, lazy)
  if qr > middle and ql <= right:
    dctAdd(node * 2 + 1, middle + 1, right, ql, qr, delta, minimum, lazy)
  minimum[node] = min(minimum[node * 2], minimum[node * 2 + 1])

proc dctFirstZero(node, left, right: int, minimum: openArray[int]): int =
  if left == right: return left
  let middle = (left + right) div 2
  if minimum[node * 2] == 0:
    return dctFirstZero(node * 2, left, middle, minimum)
  dctFirstZero(node * 2 + 1, middle + 1, right, minimum)

proc dctConnected(left, right: int, logs: openArray[int],
                  rangeMin, rangeMax: openArray[int]): bool =
  let level = logs[right - left + 1]
  let other = right + 1 - (1 shl level)
  let low = min(rangeMin[level * MaxN + left], rangeMin[level * MaxN + other])
  let high = max(rangeMax[level * MaxN + left], rangeMax[level * MaxN + other])
  high - low == right - left

proc dctNewNode(left, right: int, combine: bool, lastLeft: int,
                count: var int, nodeLeft, nodeRight: var array[MaxNodes, int],
                nodeCombine: var array[MaxNodes, bool], nodeLast: var array[MaxNodes, int]): int =
  let id = count
  inc count
  nodeLeft[id] = left
  nodeRight[id] = right
  nodeCombine[id] = combine
  nodeLast[id] = lastLeft
  id

proc divide_combine_tree_incremental*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "divide_combine_tree_incremental".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableLength): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > int64(MaxN) or length != csize_t(nValue + 1): return -1
  let n = int(nValue)
  var permutation: array[MaxN, int]
  var seen: array[MaxN, bool]
  for i in 0 ..< n:
    let value = input[i + 1]
    if value < 0 or value >= int64(n) or seen[int(value)]: return -1
    permutation[i] = int(value)
    seen[int(value)] = true

  var logs: array[MaxN + 1, int]
  for i in 2 .. n: logs[i] = logs[i div 2] + 1
  let levels = logs[n] + 1
  var rangeMin, rangeMax: array[MaxN * MaxN, int]
  for i in 0 ..< n:
    rangeMin[i] = permutation[i]
    rangeMax[i] = permutation[i]
  for level in 1 ..< levels:
    let half = 1 shl (level - 1)
    let width = half * 2
    for start in 0 .. n - width:
      rangeMin[level * MaxN + start] = min(
        rangeMin[(level - 1) * MaxN + start],
        rangeMin[(level - 1) * MaxN + start + half])
      rangeMax[level * MaxN + start] = max(
        rangeMax[(level - 1) * MaxN + start],
        rangeMax[(level - 1) * MaxN + start + half])

  var segmentMin, lazy: array[TreeSize, int]
  var nodeLeft, nodeRight, nodeLast: array[MaxNodes, int]
  var nodeCombine: array[MaxNodes, bool]
  var nodeStack, minStack, maxStack: array[MaxN, int]
  var nodeTop, minTop, maxTop, nodeCount = 0
  for ending in 0 ..< n:
    let value = permutation[ending]
    while minTop > 0 and permutation[minStack[minTop - 1]] >= value:
      dec minTop
      let position = minStack[minTop]
      let start = if minTop > 0: minStack[minTop - 1] + 1 else: 0
      dctAdd(1, 0, n - 1, start, position, permutation[position], segmentMin, lazy)
    while maxTop > 0 and permutation[maxStack[maxTop - 1]] <= value:
      dec maxTop
      let position = maxStack[maxTop]
      let start = if maxTop > 0: maxStack[maxTop - 1] + 1 else: 0
      dctAdd(1, 0, n - 1, start, position, -permutation[position], segmentMin, lazy)
    var start = if minTop > 0: minStack[minTop - 1] + 1 else: 0
    dctAdd(1, 0, n - 1, start, ending, -value, segmentMin, lazy)
    minStack[minTop] = ending
    inc minTop
    start = if maxTop > 0: maxStack[maxTop - 1] + 1 else: 0
    dctAdd(1, 0, n - 1, start, ending, value, segmentMin, lazy)
    maxStack[maxTop] = ending
    inc maxTop

    let leftmost = dctFirstZero(1, 0, n - 1, segmentMin)
    var current = dctNewNode(ending, ending, false, 0, nodeCount,
      nodeLeft, nodeRight, nodeCombine, nodeLast)
    while nodeTop > 0 and nodeLeft[nodeStack[nodeTop - 1]] >= leftmost:
      let top = nodeStack[nodeTop - 1]
      if nodeCombine[top] and dctConnected(nodeLast[top], ending, logs, rangeMin, rangeMax):
        nodeRight[top] = ending
        nodeLast[top] = nodeLeft[current]
        dec nodeTop
        current = nodeStack[nodeTop]
      elif dctConnected(nodeLeft[top], ending, logs, rangeMin, rangeMax):
        let merged = dctNewNode(nodeLeft[top], ending, true, nodeLeft[current], nodeCount,
          nodeLeft, nodeRight, nodeCombine, nodeLast)
        dec nodeTop
        current = merged
      else:
        let merged = dctNewNode(-1, ending, false, 0, nodeCount,
          nodeLeft, nodeRight, nodeCombine, nodeLast)
        dec nodeTop
        while nodeTop > 0 and not dctConnected(nodeLeft[nodeStack[nodeTop - 1]], ending,
                                                logs, rangeMin, rangeMax):
          dec nodeTop
        if nodeTop == 0: return -1
        dec nodeTop
        let base = nodeStack[nodeTop]
        nodeLeft[merged] = nodeLeft[base]
        current = merged
    nodeStack[nodeTop] = current
    inc nodeTop
    dctAdd(1, 0, n - 1, 0, ending, -1, segmentMin, lazy)

  for i in 1 ..< nodeCount:
    let left = nodeLeft[i]
    let right = nodeRight[i]
    var j = i
    while j > 0 and (nodeLeft[j - 1] > left or
        (nodeLeft[j - 1] == left and nodeRight[j - 1] > right)):
      nodeLeft[j] = nodeLeft[j - 1]
      nodeRight[j] = nodeRight[j - 1]
      dec j
    nodeLeft[j] = left
    nodeRight[j] = right
  var checksum = 0'i64
  for i in 0 ..< nodeCount:
    checksum += int64(i + 1) *
      (int64(nodeLeft[i] + 1) * int64(n + 1) + int64(nodeRight[i] + 1))
  checksum
