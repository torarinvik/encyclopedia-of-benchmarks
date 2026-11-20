const MaxValidLength = 66
const MaxParseableLength = 67

proc lazyApply(tree: var array[64, int64], pending: var array[64, int64],
               node, segmentLength: int, delta: int64) =
  tree[node] += delta * int64(segmentLength)
  pending[node] += delta

proc lazyPush(tree: var array[64, int64], pending: var array[64, int64],
              node, segmentLength: int) =
  if segmentLength > 1 and pending[node] != 0:
    let half = segmentLength div 2
    let delta = pending[node]
    lazyApply(tree, pending, 2 * node, half, delta)
    lazyApply(tree, pending, 2 * node + 1, half, delta)
    pending[node] = 0

proc lazyAdd(tree: var array[64, int64], pending: var array[64, int64],
             node, low, high, queryLow, queryHigh: int, delta: int64) =
  if queryLow >= queryHigh: return
  if queryHigh <= low or high <= queryLow: return
  if queryLow <= low and high <= queryHigh:
    lazyApply(tree, pending, node, high - low, delta)
    return
  lazyPush(tree, pending, node, high - low)
  let middle = (low + high) div 2
  if queryLow < middle: lazyAdd(tree, pending, 2 * node, low, middle, queryLow, queryHigh, delta)
  if queryHigh > middle: lazyAdd(tree, pending, 2 * node + 1, middle, high, queryLow, queryHigh, delta)
  tree[node] = tree[2 * node] + tree[2 * node + 1]

proc lazyMaxRight(tree: var array[64, int64], pending: var array[64, int64],
                  node, low, high, n, left: int, limit: int64,
                  accumulated: var int64): int =
  if high <= left: return high
  if low >= n: return n
  if left <= low and high <= n and accumulated + tree[node] <= limit:
    accumulated += tree[node]
    return high
  if high - low == 1: return low
  lazyPush(tree, pending, node, high - low)
  let middle = (low + high) div 2
  let first = lazyMaxRight(tree, pending, 2 * node, low, middle, n, left, limit, accumulated)
  if first < middle and first >= left: return first
  lazyMaxRight(tree, pending, 2 * node + 1, middle, high, n, left, limit, accumulated)

proc lazy_segment_tree_range_add_max_right*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "lazy_segment_tree_range_add_max_right".} =
  if input == nil or length < 3 or length > csize_t(MaxParseableLength): return -1
  if input[0] < 1 or input[0] > 16 or input[1] < 0 or input[1] > 12: return -1
  let n = int(input[0])
  let operations = int(input[1])
  if int(length) != 2 + n + 4 * operations or int(length) > MaxValidLength: return -1
  for i in 0 ..< n:
    if input[2 + i] < 0 or input[2 + i] > 31: return -1
  for operation in 0 ..< operations:
    let p = 2 + n + 4 * operation
    let opcode, left, right, extra = input[p], input[p + 1], input[p + 2], input[p + 3]
    if opcode == 0:
      if left < 0 or left > int64(n) or right < left or right > int64(n) or extra < 0 or extra > 31: return -1
    elif opcode == 1:
      if left < 0 or left > int64(n) or right < 0 or right > 8192 or extra != 0: return -1
    else: return -1

  var base = 1
  while base < n: base *= 2
  var tree: array[64, int64]
  var pending: array[64, int64]
  for i in 0 ..< n: tree[base + i] = input[2 + i]
  var node = base
  while node > 1:
    dec node
    tree[node] = tree[2 * node] + tree[2 * node + 1]

  var queryIndex = 0
  var result = 0'i64
  for operation in 0 ..< operations:
    let p = 2 + n + 4 * operation
    let left = int(input[p + 1])
    let right = input[p + 2]
    if input[p] == 0:
      lazyAdd(tree, pending, 1, 0, base, left, int(input[p + 2]), input[p + 3])
    else:
      var accumulated = 0'i64
      let boundary = lazyMaxRight(tree, pending, 1, 0, base, n, left, right, accumulated)
      result = result or (int64(boundary) shl (5 * queryIndex))
      inc queryIndex
  result
