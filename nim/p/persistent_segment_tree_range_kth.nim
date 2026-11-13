const
  MaxN = 32
  MaxQ = 32
  MaxInputLength = 131
  MaxNodes = 193
  InvalidResult = low(int64)

proc persistent_segment_tree_range_kth*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "persistent_segment_tree_range_kth".} =
  if input.isNil or length < 2 or length > MaxInputLength: return InvalidResult
  if input[0] < 1 or input[0] > MaxN or input[1] < 0 or input[1] > MaxQ: return InvalidResult
  let n = int(input[0])
  let q = int(input[1])
  if int(length) != 2 + n + 3 * q: return InvalidResult

  var coordinates: array[MaxN, int64]
  for i in 0 ..< n:
    let value = input[2 + i]
    if value < -1000 or value > 1000: return InvalidResult
    coordinates[i] = value
  for i in 1 ..< n:
    let value = coordinates[i]
    var j = i
    while j > 0 and coordinates[j - 1] > value:
      coordinates[j] = coordinates[j - 1]
      dec j
    coordinates[j] = value
  var distinct = 0
  for i in 0 ..< n:
    if distinct == 0 or coordinates[i] != coordinates[distinct - 1]:
      coordinates[distinct] = coordinates[i]
      inc distinct
  let queryOffset = 2 + n
  for qi in 0 ..< q:
    let at = queryOffset + 3 * qi
    let left = input[at]
    let right = input[at + 1]
    let k = input[at + 2]
    if left < 0 or right < left or right >= int64(n) or k < 1 or k > right - left + 1:
      return InvalidResult

  var leftChild: array[MaxNodes, int32]
  var rightChild: array[MaxNodes, int32]
  var counts: array[MaxNodes, int32]
  var roots: array[MaxN + 1, int32]
  var nodeCount = 1
  for i in 0 ..< n:
    let value = input[2 + i]
    var low = 0
    var high = distinct
    while low < high:
      let middle = low + (high - low) div 2
      if coordinates[middle] < value: low = middle + 1
      else: high = middle
    let rank = low
    let previousRoot = int(roots[i])
    if nodeCount >= MaxNodes: return InvalidResult
    let newRoot = nodeCount
    inc nodeCount
    leftChild[newRoot] = leftChild[previousRoot]
    rightChild[newRoot] = rightChild[previousRoot]
    counts[newRoot] = counts[previousRoot] + 1
    var oldNode = previousRoot
    var newNode = newRoot
    low = 0
    high = distinct
    while high - low > 1:
      let middle = low + (high - low) div 2
      let oldChild = int(if rank < middle: leftChild[oldNode] else: rightChild[oldNode])
      if nodeCount >= MaxNodes: return InvalidResult
      let newChild = nodeCount
      inc nodeCount
      leftChild[newChild] = leftChild[oldChild]
      rightChild[newChild] = rightChild[oldChild]
      counts[newChild] = counts[oldChild] + 1
      if rank < middle:
        leftChild[newNode] = int32(newChild)
        high = middle
      else:
        rightChild[newNode] = int32(newChild)
        low = middle
      oldNode = oldChild
      newNode = newChild
    roots[i + 1] = int32(newRoot)

  var checksum = 0'i64
  for qi in 0 ..< q:
    let at = queryOffset + 3 * qi
    let left = int(input[at])
    let right = int(input[at + 1])
    var k = int(input[at + 2])
    var before = int(roots[left])
    var after = int(roots[right + 1])
    var low = 0
    var high = distinct
    while high - low > 1:
      let middle = low + (high - low) div 2
      let inLeft = int(leftChild[after])
      let outLeft = int(leftChild[before])
      let leftCount = int(counts[inLeft] - counts[outLeft])
      if k <= leftCount:
        before = outLeft
        after = inLeft
        high = middle
      else:
        k -= leftCount
        before = int(rightChild[before])
        after = int(rightChild[after])
        low = middle
    checksum += int64(qi + 1) * coordinates[low]
  checksum
