const
  MaxOperations = 512
  MaxNodes = MaxOperations * 24 + 1
  DomainLow = -1_000_000'i64
  DomainHigh = 1_000_000'i64
  CoefficientLimit = 1_000'i64
  ChecksumOffset = 1_000_001_001'i64

type
  LineNode = object
    slope, intercept: int64
    left, right: int
    occupied: bool
  LiChaoTree = object
    nodes: array[MaxNodes, LineNode]
    used: int
    root: int

proc evaluate(slope, intercept, x: int64): int64 =
  slope * x + intercept

proc allocate(tree: var LiChaoTree): int =
  if tree.used >= MaxNodes: return -1
  result = tree.used
  inc tree.used
  tree.nodes[result].left = -1
  tree.nodes[result].right = -1
  tree.nodes[result].occupied = false

proc insertAt(tree: var LiChaoTree, nodeId: int, low, high: int64,
              newSlope, newIntercept: int64): bool =
  if not tree.nodes[nodeId].occupied:
    tree.nodes[nodeId].slope = newSlope
    tree.nodes[nodeId].intercept = newIntercept
    tree.nodes[nodeId].occupied = true
    return true

  let middle = low + (high - low) div 2
  var slope = newSlope
  var intercept = newIntercept
  if evaluate(slope, intercept, middle) < evaluate(tree.nodes[nodeId].slope, tree.nodes[nodeId].intercept, middle):
    swap(slope, tree.nodes[nodeId].slope)
    swap(intercept, tree.nodes[nodeId].intercept)
  if low == high: return true

  var goLeft = false
  var nextLow = middle + 1
  var nextHigh = high
  if evaluate(slope, intercept, low) < evaluate(tree.nodes[nodeId].slope, tree.nodes[nodeId].intercept, low):
    goLeft = true
    nextLow = low
    nextHigh = middle
  elif evaluate(slope, intercept, high) >= evaluate(tree.nodes[nodeId].slope, tree.nodes[nodeId].intercept, high):
    return true

  var child = if goLeft: tree.nodes[nodeId].left else: tree.nodes[nodeId].right
  if child < 0:
    child = allocate(tree)
    if child < 0: return false
    if goLeft: tree.nodes[nodeId].left = child else: tree.nodes[nodeId].right = child
  insertAt(tree, child, nextLow, nextHigh, slope, intercept)

proc addLine(tree: var LiChaoTree, slope, intercept: int64): bool =
  if tree.root < 0:
    tree.root = allocate(tree)
    if tree.root < 0: return false
  insertAt(tree, tree.root, DomainLow, DomainHigh, slope, intercept)

proc minimumAt(tree: var LiChaoTree, nodeId: int, low, high, x: int64): int64 =
  let node = tree.nodes[nodeId]
  result = evaluate(node.slope, node.intercept, x)
  if low == high: return
  let middle = low + (high - low) div 2
  let goLeft = x <= middle
  let child = if goLeft: node.left else: node.right
  if child >= 0:
    let nested = minimumAt(tree, child, (if goLeft: low else: middle + 1),
                           (if goLeft: middle else: high), x)
    if nested < result: result = nested

proc li_chao_tree*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "li_chao_tree".} =
  if values == nil or length < 1 or length > csize_t(1 + 3 * MaxOperations): return -1
  if values[0] < 0 or values[0] > int64(MaxOperations): return -1
  let operationCount = int(values[0])
  if length != csize_t(1 + 3 * operationCount): return -1

  var tree: LiChaoTree
  tree.root = -1
  var inserted = 0
  var queryNumber = 0'i64
  var checksum = 0'i64
  for operation in 0 ..< operationCount:
    let offset = 1 + 3 * operation
    let opcode = values[offset]
    let first = values[offset + 1]
    let second = values[offset + 2]
    if opcode == 0:
      if first < -CoefficientLimit or first > CoefficientLimit or second < -CoefficientLimit or second > CoefficientLimit:
        return -1
      if not addLine(tree, first, second): return -1
      inc inserted
    elif opcode == 1:
      if first < DomainLow or first > DomainHigh or second != 0 or inserted == 0: return -1
      let answer = minimumAt(tree, tree.root, DomainLow, DomainHigh, first)
      inc queryNumber
      checksum += queryNumber * (answer + ChecksumOffset)
    else:
      return -1
  checksum
