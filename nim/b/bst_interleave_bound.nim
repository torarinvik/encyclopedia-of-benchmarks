const
  MaxNodes = 8
  MaxAccesses = 16
  MaxInput = 36

proc storeI64Le(output: ptr UncheckedArray[uint8], value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[byte] = uint8((bits shr (8 * byte)) and 255)

proc bst_interleave_bound*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "bst_interleave_bound".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let nRaw, rootRaw = input[0], input[1]
  if nRaw < 1 or nRaw > MaxNodes or rootRaw < 0 or rootRaw >= nRaw: return -1
  let n, root = int(nRaw), int(rootRaw)
  var left, right, parent: array[MaxNodes, int]
  var parentCount: array[MaxNodes, int]
  for i in 0 ..< MaxNodes: left[i] = -1; right[i] = -1; parent[i] = -1
  var position = 2
  for node in 0 ..< n:
    if position + 2 > int(length): return -1
    let l, r = int(input[position]), int(input[position + 1])
    position += 2
    if l < -1 or l >= n or r < -1 or r >= n or l == node or r == node or (l >= 0 and l == r): return -1
    left[node] = l; right[node] = r
    if l >= 0: inc parentCount[l]; parent[l] = node
    if r >= 0: inc parentCount[r]; parent[r] = node
  if parentCount[root] != 0: return -1
  for node in 0 ..< n:
    if node != root and parentCount[node] != 1: return -1
  if position >= int(length): return -1
  let mRaw = input[position]
  inc position
  if mRaw < 0 or mRaw > MaxAccesses or int(length) != position + int(mRaw): return -1
  let m = int(mRaw)
  var accesses: array[MaxAccesses, int]
  for i in 0 ..< m:
    let key = input[position]
    inc position
    if key < 0 or key >= nRaw: return -1
    accesses[i] = int(key)

  var stackNode, stackLow, stackHigh: array[MaxNodes, int]
  var visited: array[MaxNodes, bool]
  var stackSize = 1
  var visitedCount = 0
  stackNode[0] = root; stackLow[0] = -1; stackHigh[0] = n
  while stackSize > 0:
    dec stackSize
    let node, low, high = stackNode[stackSize], stackLow[stackSize], stackHigh[stackSize]
    if visited[node] or node <= low or node >= high: return -1
    visited[node] = true; inc visitedCount
    if left[node] >= 0:
      stackNode[stackSize] = left[node]; stackLow[stackSize] = low; stackHigh[stackSize] = node
      inc stackSize
    if right[node] >= 0:
      stackNode[stackSize] = right[node]; stackLow[stackSize] = node; stackHigh[stackSize] = high
      inc stackSize
  if visitedCount != n: return -1

  var bound = 0'i64
  for pivot in 0 ..< n:
    var previous = -1
    for i in 0 ..< m:
      let key = accesses[i]
      var ancestor = key
      while ancestor >= 0 and ancestor != pivot: ancestor = parent[ancestor]
      if ancestor == pivot:
        let side = if key <= pivot: 0 else: 1
        if previous >= 0 and side != previous: inc bound
        previous = side
  if output.isNil or capacity < csize_t(8): return -2
  storeI64Le(output, bound)
  8
