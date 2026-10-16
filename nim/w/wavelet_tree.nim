const MaxN = 64
const MaxQ = 128
const MaxNodes = 768
type WaveletNode = object
  low, high: int64
  left, right: int
  prefix: array[MaxN + 1, uint8]
type WaveletTree = array[MaxNodes, WaveletNode]

proc build(tree: var WaveletTree, used: var int, values: openArray[int64], low, high: int64): int =
  result = used
  inc used
  tree[result].low = low
  tree[result].high = high
  tree[result].left = -1
  tree[result].right = -1
  tree[result].prefix[0] = 0
  if low == high or values.len == 0: return
  let mid = low + (high - low) div 2
  var leftValues, rightValues: array[MaxN, int64]
  var leftCount, rightCount = 0
  for i, value in values:
    if value <= mid:
      leftValues[leftCount] = value
      inc leftCount
    else:
      rightValues[rightCount] = value
      inc rightCount
    tree[result].prefix[i + 1] = uint8(leftCount)
  if leftCount > 0:
    tree[result].left = build(tree, used, leftValues.toOpenArray(0, leftCount - 1), low, mid)
  if rightCount > 0:
    tree[result].right = build(tree, used, rightValues.toOpenArray(0, rightCount - 1), mid + 1, high)

proc rankPrefix(tree: var WaveletTree, nodeId: int, value: int64, count: int): int64 =
  if nodeId < 0 or count == 0: return 0
  let node = tree[nodeId]
  if node.low == node.high: return (if node.low == value: int64(count) else: 0)
  let mid = node.low + (node.high - node.low) div 2
  let leftCount = int(node.prefix[count])
  if value <= mid: return rankPrefix(tree, node.left, value, leftCount)
  rankPrefix(tree, node.right, value, count - leftCount)

proc quantile(tree: var WaveletTree, nodeId: int, left, right, k: int): int64 =
  let node = tree[nodeId]
  if node.low == node.high: return node.low
  let leftBefore = int(node.prefix[left])
  let leftAfter = int(node.prefix[right])
  let inLeft = leftAfter - leftBefore
  if k < inLeft: return quantile(tree, node.left, leftBefore, leftAfter, k)
  quantile(tree, node.right, left - leftBefore, right - leftAfter, k - inLeft)

proc rangeCount(tree: var WaveletTree, nodeId: int, left, right: int, low, high: int64): int64 =
  if nodeId < 0 or left >= right: return 0
  let node = tree[nodeId]
  if high < node.low or low > node.high: return 0
  if low <= node.low and node.high <= high: return int64(right - left)
  if node.low == node.high: return 0
  let leftBefore = int(node.prefix[left])
  let leftAfter = int(node.prefix[right])
  rangeCount(tree, node.left, leftBefore, leftAfter, low, high) +
    rangeCount(tree, node.right, left - leftBefore, right - leftAfter, low, high)

proc wavelet_tree_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "wavelet_tree_benchmark".} =
  if values == nil or length < 3 or length > csize_t(MaxN + 2 + 5 * MaxQ): return -1
  if values[0] < 1 or values[0] > int64(MaxN): return -1
  let n = int(values[0])
  if length < csize_t(n + 2): return -1
  var data: array[MaxN, int64]
  var low, high = values[1]
  for i in 0 ..< n:
    data[i] = values[i + 1]
    if data[i] < -1000 or data[i] > 1000: return -1
    if data[i] < low: low = data[i]
    if data[i] > high: high = data[i]
  let qValue = values[n + 1]
  if qValue < 0 or qValue > int64(MaxQ) or length != csize_t(n + 2 + 5 * int(qValue)): return -1
  let q = int(qValue)
  let tree = cast[ptr WaveletTree](allocShared0(sizeof(WaveletTree)))
  if tree.isNil: return -1
  defer: deallocShared(tree)
  var used = 0
  let root = build(tree[], used, data.toOpenArray(0, n - 1), low, high)
  var total = 0'i64
  for j in 0 ..< q:
    let p = n + 2 + 5 * j
    let (op, a, b, c, d) = (values[p], values[p + 1], values[p + 2], values[p + 3], values[p + 4])
    var answer = 0'i64
    if op == 0:
      if a < -1000 or a > 1000 or b < -1 or b >= int64(n): return -1
      answer = rankPrefix(tree[], root, a, int(b + 1))
    elif op == 1:
      if a < 0 or b < a or b >= int64(n) or c < 0 or c > b - a: return -1
      answer = quantile(tree[], root, int(a), int(b + 1), int(c))
    elif op == 2:
      if a < 0 or b < a or b >= int64(n) or c > d or c < -1000 or d > 1000: return -1
      answer = rangeCount(tree[], root, int(a), int(b + 1), c, d)
    else:
      return -1
    total += int64(j + 1) * (answer + 1_000_001)
  total
