const MaxQueues = 8
const MaxOperations = 64
const MaxParseableWords = 259
const Nil = -1'i64

proc branchStack(root: int64, rightBranch: bool, nodeCount: int,
    leftmost, rightmost: openArray[int64],
    stack: var array[MaxOperations, int64]): int =
  var node = if rightBranch: rightmost[root.int] else: leftmost[root.int]
  if node < 0 or node >= nodeCount.int64: return -1
  var count = 0
  while count < nodeCount:
    stack[count] = node
    inc count
    if node == root: return count
    node = if rightBranch: rightmost[node.int] else: leftmost[node.int]
    if node < 0 or node >= nodeCount.int64: return -1
  -1

proc pagodaMeld(gRoot, dRoot: int64, nodeCount: int,
    keys: openArray[int64],
    leftmost, rightmost: var array[MaxOperations, int64]): int64 =
  if gRoot < 0: return dRoot
  if dRoot < 0: return gRoot
  var gBranch, dBranch: array[MaxOperations, int64]
  let gCount = branchStack(gRoot, true, nodeCount, leftmost, rightmost, gBranch)
  let dCount = branchStack(dRoot, false, nodeCount, leftmost, rightmost, dBranch)
  if gCount < 1 or dCount < 1: return -2

  var gi, di = 0
  var central, centralLeft, centralRight = Nil
  while gi < gCount or di < dCount:
    let takeG = di >= dCount or
      (gi < gCount and keys[gBranch[gi].int] > keys[dBranch[di].int])
    var node, keptExtreme: int64
    if takeG:
      node = gBranch[gi]
      inc gi
      keptExtreme = leftmost[node.int]
    else:
      node = dBranch[di]
      inc di
      keptExtreme = rightmost[node.int]

    if central >= 0:
      if takeG:
        rightmost[central.int] = node
        leftmost[central.int] = if centralLeft == central: Nil else: centralLeft
      else:
        leftmost[central.int] = node
        rightmost[central.int] = if centralRight == central: Nil else: centralRight

    var newLeft, newRight: int64
    if takeG:
      newLeft = if keptExtreme < 0: node else: keptExtreme
      newRight = if central >= 0: centralRight else: node
    else:
      newLeft = if central >= 0: centralLeft else: node
      newRight = if keptExtreme < 0: node else: keptExtreme
    leftmost[node.int] = newLeft
    rightmost[node.int] = newRight
    central = node
    centralLeft = newLeft
    centralRight = newRight
  central

proc pagodaExtractMin(root: int64, nodeCount: int,
    keys: openArray[int64],
    leftmost, rightmost: var array[MaxOperations, int64]): int64 =
  let oldLeftmost = leftmost[root.int]
  let oldRightmost = rightmost[root.int]
  var leftChild, rightChild = Nil
  if oldLeftmost != root:
    var node = oldLeftmost
    var steps = 0
    while node >= 0 and node < nodeCount.int64 and leftmost[node.int] != root and steps < nodeCount:
      node = leftmost[node.int]
      inc steps
    if node < 0 or node >= nodeCount.int64 or leftmost[node.int] != root: return -2
    leftChild = node
  if oldRightmost != root:
    var node = oldRightmost
    var steps = 0
    while node >= 0 and node < nodeCount.int64 and rightmost[node.int] != root and steps < nodeCount:
      node = rightmost[node.int]
      inc steps
    if node < 0 or node >= nodeCount.int64 or rightmost[node.int] != root: return -2
    rightChild = node

  if leftChild >= 0:
    leftmost[leftChild.int] = oldLeftmost
    if rightmost[leftChild.int] < 0: rightmost[leftChild.int] = leftChild
  if rightChild >= 0:
    rightmost[rightChild.int] = oldRightmost
    if leftmost[rightChild.int] < 0: leftmost[rightChild.int] = rightChild
  let newRoot = pagodaMeld(rightChild, leftChild, nodeCount, keys, leftmost, rightmost)
  leftmost[root.int] = Nil
  rightmost[root.int] = Nil
  newRoot

proc pagoda_meldable_priority_queue*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "pagoda_meldable_priority_queue".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxParseableWords): return -1
  let rawQueues = input[0]
  let rawOperations = input[1]
  if rawQueues < 1 or rawQueues > MaxQueues.int64 or rawOperations < 0 or
      rawOperations > MaxOperations.int64 or length != csize_t(2 + 4 * rawOperations) or
      length > csize_t(258): return -1

  var keys: array[MaxOperations, int64]
  var leftmost, rightmost: array[MaxOperations, int64]
  var roots: array[MaxQueues, int64]
  for i in 0 ..< MaxOperations:
    leftmost[i] = Nil
    rightmost[i] = Nil
  for i in 0 ..< MaxQueues: roots[i] = Nil
  var nodeCount = 0
  var result = 0'i64

  for op in 0 ..< rawOperations.int:
    let offset = 2 + 4 * op
    let opcode = input[offset]
    let first = input[offset + 1]
    let second = input[offset + 2]
    let priority = input[offset + 3]
    if opcode == 1:
      if first < 0 or first >= rawQueues or second != 0 or priority < -1000 or
          priority > 1000 or nodeCount >= MaxOperations: return -1
      for i in 0 ..< nodeCount:
        if keys[i] == priority: return -1
      let node = nodeCount.int64
      inc nodeCount
      keys[node.int] = priority
      leftmost[node.int] = node
      rightmost[node.int] = node
      let merged = pagodaMeld(roots[first.int], node, nodeCount, keys, leftmost, rightmost)
      if merged < 0: return -1
      roots[first.int] = merged
    elif opcode == 2:
      if first < 0 or first >= rawQueues or second < 0 or second >= rawQueues or
          first == second or priority != 0: return -1
      let merged = pagodaMeld(roots[first.int], roots[second.int], nodeCount, keys, leftmost, rightmost)
      if merged == -2: return -1
      roots[first.int] = merged
      roots[second.int] = Nil
    elif opcode == 3 or opcode == 4:
      if first < 0 or first >= rawQueues or second != 0 or priority != 0 or roots[first.int] < 0:
        return -1
      let root = roots[first.int]
      result += (op.int64 + 1) * (keys[root.int] + 1001)
      if opcode == 4:
        let newRoot = pagodaExtractMin(root, nodeCount, keys, leftmost, rightmost)
        if newRoot == -2: return -1
        roots[first.int] = newRoot
    else:
      return -1
  result
