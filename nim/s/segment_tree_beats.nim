const
  MaxItems = 64
  MaxOperations = 128
  MaxInputValues = 2 + MaxItems + 4 * MaxOperations
  TreeSize = 4 * MaxItems
  ValueLimit = 1_000_000'i64
  Inf = 2_305_843_009_213_693_951'i64
  QueryOffset = 8_256_000_001'i64

type SegmentNode = object
  sum, max1, max2, min1, min2, add: int64
  maxCount, minCount: int

proc pull(tree: var array[TreeSize, SegmentNode], node: int) =
  let left = tree[2 * node]
  let right = tree[2 * node + 1]
  tree[node].sum = left.sum + right.sum
  tree[node].add = 0
  if left.max1 == right.max1:
    tree[node].max1 = left.max1
    tree[node].max2 = max(left.max2, right.max2)
    tree[node].maxCount = left.maxCount + right.maxCount
  elif left.max1 > right.max1:
    tree[node].max1 = left.max1
    tree[node].max2 = max(left.max2, right.max1)
    tree[node].maxCount = left.maxCount
  else:
    tree[node].max1 = right.max1
    tree[node].max2 = max(left.max1, right.max2)
    tree[node].maxCount = right.maxCount
  if left.min1 == right.min1:
    tree[node].min1 = left.min1
    tree[node].min2 = min(left.min2, right.min2)
    tree[node].minCount = left.minCount + right.minCount
  elif left.min1 < right.min1:
    tree[node].min1 = left.min1
    tree[node].min2 = min(left.min2, right.min1)
    tree[node].minCount = left.minCount
  else:
    tree[node].min1 = right.min1
    tree[node].min2 = min(left.min1, right.min2)
    tree[node].minCount = right.minCount

proc build(tree: var array[TreeSize, SegmentNode], values: ptr UncheckedArray[int64],
           valueOffset, node, low, high: int) =
  if high - low == 1:
    let value = values[valueOffset + low]
    tree[node] = SegmentNode(sum: value, max1: value, max2: -Inf,
      min1: value, min2: Inf, add: 0, maxCount: 1, minCount: 1)
    return
  let middle = low + (high - low) div 2
  build(tree, values, valueOffset, 2 * node, low, middle)
  build(tree, values, valueOffset, 2 * node + 1, middle, high)
  pull(tree, node)

proc applyAdd(item: var SegmentNode, length: int, delta: int64) =
  item.sum += delta * int64(length)
  item.max1 += delta
  item.min1 += delta
  if item.max2 != -Inf: item.max2 += delta
  if item.min2 != Inf: item.min2 += delta
  item.add += delta

proc applyChmin(item: var SegmentNode, ceiling: int64) =
  if item.max1 <= ceiling: return
  item.sum += (ceiling - item.max1) * int64(item.maxCount)
  if item.min1 == item.max1: item.min1 = ceiling
  elif item.min2 == item.max1: item.min2 = ceiling
  item.max1 = ceiling

proc applyChmax(item: var SegmentNode, floor: int64) =
  if item.min1 >= floor: return
  item.sum += (floor - item.min1) * int64(item.minCount)
  if item.max1 == item.min1: item.max1 = floor
  elif item.max2 == item.min1: item.max2 = floor
  item.min1 = floor

proc push(tree: var array[TreeSize, SegmentNode], node, low, high: int) =
  if high - low == 1: return
  let middle = low + (high - low) div 2
  let delta = tree[node].add
  if delta != 0:
    applyAdd(tree[2 * node], middle - low, delta)
    applyAdd(tree[2 * node + 1], high - middle, delta)
    tree[node].add = 0
  let max1 = tree[node].max1
  if tree[2 * node].max1 > max1: applyChmin(tree[2 * node], max1)
  if tree[2 * node + 1].max1 > max1: applyChmin(tree[2 * node + 1], max1)
  let min1 = tree[node].min1
  if tree[2 * node].min1 < min1: applyChmax(tree[2 * node], min1)
  if tree[2 * node + 1].min1 < min1: applyChmax(tree[2 * node + 1], min1)

proc rangeAdd(tree: var array[TreeSize, SegmentNode], node, low, high, ql, qr: int, delta: int64) =
  if qr <= low or high <= ql or delta == 0: return
  if ql <= low and high <= qr:
    applyAdd(tree[node], high - low, delta)
    return
  push(tree, node, low, high)
  let middle = low + (high - low) div 2
  rangeAdd(tree, 2 * node, low, middle, ql, qr, delta)
  rangeAdd(tree, 2 * node + 1, middle, high, ql, qr, delta)
  pull(tree, node)

proc rangeChmin(tree: var array[TreeSize, SegmentNode], node, low, high, ql, qr: int, ceiling: int64) =
  if qr <= low or high <= ql or tree[node].max1 <= ceiling: return
  if ql <= low and high <= qr and tree[node].max2 < ceiling:
    applyChmin(tree[node], ceiling)
    return
  push(tree, node, low, high)
  let middle = low + (high - low) div 2
  rangeChmin(tree, 2 * node, low, middle, ql, qr, ceiling)
  rangeChmin(tree, 2 * node + 1, middle, high, ql, qr, ceiling)
  pull(tree, node)

proc rangeChmax(tree: var array[TreeSize, SegmentNode], node, low, high, ql, qr: int, floor: int64) =
  if qr <= low or high <= ql or tree[node].min1 >= floor: return
  if ql <= low and high <= qr and tree[node].min2 > floor:
    applyChmax(tree[node], floor)
    return
  push(tree, node, low, high)
  let middle = low + (high - low) div 2
  rangeChmax(tree, 2 * node, low, middle, ql, qr, floor)
  rangeChmax(tree, 2 * node + 1, middle, high, ql, qr, floor)
  pull(tree, node)

proc rangeSum(tree: var array[TreeSize, SegmentNode], node, low, high, ql, qr: int): int64 =
  if qr <= low or high <= ql: return 0
  if ql <= low and high <= qr: return tree[node].sum
  push(tree, node, low, high)
  let middle = low + (high - low) div 2
  rangeSum(tree, 2 * node, low, middle, ql, qr) +
    rangeSum(tree, 2 * node + 1, middle, high, ql, qr)

proc segment_tree_beats*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "segment_tree_beats".} =
  if values == nil or length < 2 or length > csize_t(MaxInputValues): return -1
  if values[0] < 1 or values[0] > int64(MaxItems): return -1
  let n = int(values[0])
  if length < csize_t(n + 2) or values[n + 1] < 0 or values[n + 1] > int64(MaxOperations): return -1
  let q = int(values[n + 1])
  if length != csize_t(n + 2 + 4 * q): return -1
  for i in 0 ..< n:
    if values[i + 1] < -ValueLimit or values[i + 1] > ValueLimit: return -1
  for i in 0 ..< q:
    let p = n + 2 + 4 * i
    let opcode = values[p]
    let left = values[p + 1]
    let right = values[p + 2]
    let argument = values[p + 3]
    if opcode < 0 or opcode > 3 or left < 0 or left >= right or right > int64(n): return -1
    if (opcode == 3 and argument != 0) or (opcode != 3 and (argument < -ValueLimit or argument > ValueLimit)): return -1

  var tree: array[TreeSize, SegmentNode]
  build(tree, values, 1, 1, 0, n)
  var checksum = 0'i64
  var ordinal = 0'i64
  for i in 0 ..< q:
    let p = n + 2 + 4 * i
    let left = int(values[p + 1])
    let right = int(values[p + 2])
    let argument = values[p + 3]
    case values[p]
    of 0: rangeChmin(tree, 1, 0, n, left, right, argument)
    of 1: rangeChmax(tree, 1, 0, n, left, right, argument)
    of 2: rangeAdd(tree, 1, 0, n, left, right, argument)
    else:
      inc ordinal
      checksum += ordinal * (rangeSum(tree, 1, 0, n, left, right) + QueryOffset)
  checksum
