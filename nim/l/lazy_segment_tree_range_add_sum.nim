const
  MaxItems = 256
  MaxOperations = 512
  MaxInputLength = 2306
  ValueLimit = 1_000_000'i64
  QueryOffset = 131_328_000_001'i64

proc lazyApply(tree: var array[512, int64], pending: var array[512, int64],
               node, segmentLength: int, delta: int64) =
  tree[node] += delta * int64(segmentLength)
  pending[node] += delta

proc lazyPush(tree: var array[512, int64], pending: var array[512, int64],
              node, segmentLength: int) =
  if segmentLength > 1 and pending[node] != 0:
    let childLength = segmentLength div 2
    lazyApply(tree, pending, 2 * node, childLength, pending[node])
    lazyApply(tree, pending, 2 * node + 1, childLength, pending[node])
    pending[node] = 0

proc lazyAdd(tree: var array[512, int64], pending: var array[512, int64],
             node, low, high, queryLow, queryHigh: int, delta: int64) =
  if queryLow <= low and high <= queryHigh:
    lazyApply(tree, pending, node, high - low, delta)
    return
  lazyPush(tree, pending, node, high - low)
  let middle = (low + high) div 2
  if queryLow < middle:
    lazyAdd(tree, pending, 2 * node, low, middle, queryLow, queryHigh, delta)
  if queryHigh > middle:
    lazyAdd(tree, pending, 2 * node + 1, middle, high, queryLow, queryHigh, delta)
  tree[node] = tree[2 * node] + tree[2 * node + 1]

proc lazySum(tree: var array[512, int64], pending: var array[512, int64],
             node, low, high, queryLow, queryHigh: int): int64 =
  if queryLow <= low and high <= queryHigh:
    return tree[node]
  lazyPush(tree, pending, node, high - low)
  let middle = (low + high) div 2
  var result = 0'i64
  if queryLow < middle:
    result += lazySum(tree, pending, 2 * node, low, middle, queryLow, queryHigh)
  if queryHigh > middle:
    result += lazySum(tree, pending, 2 * node + 1, middle, high, queryLow, queryHigh)
  result

proc lazy_segment_tree_range_add_sum*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "lazy_segment_tree_range_add_sum".} =
  if values == nil or length < 3 or length > csize_t(MaxInputLength):
    return -1
  let itemCountValue = values[0]
  if itemCountValue < 1 or itemCountValue > int64(MaxItems):
    return -1
  let itemCount = int(itemCountValue)
  if length < csize_t(itemCount + 2):
    return -1
  let operationCountValue = values[itemCount + 1]
  if operationCountValue < 0 or operationCountValue > int64(MaxOperations):
    return -1
  let operationCount = int(operationCountValue)
  if length != csize_t(itemCount + 2 + 4 * operationCount):
    return -1

  for index in 0 ..< itemCount:
    if values[index + 1] < -ValueLimit or values[index + 1] > ValueLimit:
      return -1
  for operation in 0 ..< operationCount:
    let position = itemCount + 2 + 4 * operation
    let opcode = values[position]
    let left = values[position + 1]
    let right = values[position + 2]
    let delta = values[position + 3]
    if left < 0 or left >= right or right > itemCountValue:
      return -1
    if opcode == 0:
      if delta < -ValueLimit or delta > ValueLimit:
        return -1
    elif opcode == 1:
      if delta != 0:
        return -1
    else:
      return -1

  var base = 1
  while base < itemCount:
    base *= 2
  var tree: array[512, int64]
  var pending: array[512, int64]
  for index in 0 ..< itemCount:
    tree[base + index] = values[index + 1]
  var node = base
  while node > 1:
    dec node
    tree[node] = tree[2 * node] + tree[2 * node + 1]

  var checksum = 0'i64
  for operation in 0 ..< operationCount:
    let position = itemCount + 2 + 4 * operation
    let left = int(values[position + 1])
    let right = int(values[position + 2])
    if values[position] == 0:
      lazyAdd(tree, pending, 1, 0, base, left, right, values[position + 3])
    else:
      checksum += lazySum(tree, pending, 1, 0, base, left, right) + QueryOffset
  checksum
