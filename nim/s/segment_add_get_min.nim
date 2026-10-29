const
  MaxInitialSegments = 16
  MaxOperations = 32
  DomainLow = -32'i64
  DomainHigh = 31'i64
  DomainRight = 32'i64
  CoefficientLimit = 1_000'i64
  InfinityValue = 1_000_000_000_000'i64
  ChecksumOffset = 33_001'i64
  TreeCapacity = 4 * 64 + 8
  MaxInputLength = 2 + 4 * MaxInitialSegments + 5 * MaxOperations

type
  LineNode = object
    slope, intercept: int64
    occupied: bool
  SegmentLiChao = object
    nodes: array[TreeCapacity, LineNode]

proc evaluate(slope, intercept, x: int64): int64 =
  slope * x + intercept

proc addLine(tree: var SegmentLiChao, node: int, low, high: int64,
             newSlope, newIntercept: int64) =
  if not tree.nodes[node].occupied:
    tree.nodes[node].slope = newSlope
    tree.nodes[node].intercept = newIntercept
    tree.nodes[node].occupied = true
    return

  let middle = low + (high - low) div 2
  var slope = newSlope
  var intercept = newIntercept
  if evaluate(slope, intercept, middle) < evaluate(tree.nodes[node].slope, tree.nodes[node].intercept, middle):
    swap(slope, tree.nodes[node].slope)
    swap(intercept, tree.nodes[node].intercept)
  if low == high: return
  if evaluate(slope, intercept, low) < evaluate(tree.nodes[node].slope, tree.nodes[node].intercept, low):
    addLine(tree, 2 * node, low, middle, slope, intercept)
  elif evaluate(slope, intercept, high) < evaluate(tree.nodes[node].slope, tree.nodes[node].intercept, high):
    addLine(tree, 2 * node + 1, middle + 1, high, slope, intercept)

proc addSegment(tree: var SegmentLiChao, node: int, low, high: int64,
                queryLow, queryHigh, slope, intercept: int64) =
  if queryHigh <= low or high < queryLow: return
  if queryLow <= low and high < queryHigh:
    addLine(tree, node, low, high, slope, intercept)
    return
  let middle = low + (high - low) div 2
  addSegment(tree, 2 * node, low, middle, queryLow, queryHigh, slope, intercept)
  addSegment(tree, 2 * node + 1, middle + 1, high, queryLow, queryHigh, slope, intercept)

proc minimumAt(tree: SegmentLiChao, node: int, low, high, x: int64): int64 =
  result = InfinityValue
  if tree.nodes[node].occupied:
    result = evaluate(tree.nodes[node].slope, tree.nodes[node].intercept, x)
  if low == high: return
  let middle = low + (high - low) div 2
  if x <= middle:
    result = min(result, minimumAt(tree, 2 * node, low, middle, x))
  else:
    result = min(result, minimumAt(tree, 2 * node + 1, middle + 1, high, x))

proc validSegment(left, right, slope, intercept: int64): bool =
  left >= DomainLow and left < right and right <= DomainRight and
    slope >= -CoefficientLimit and slope <= CoefficientLimit and
    intercept >= -CoefficientLimit and intercept <= CoefficientLimit

proc segment_add_get_min*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "segment_add_get_min".} =
  if values == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let initialValue = values[0]
  let operationValue = values[1]
  if initialValue < 0 or initialValue > int64(MaxInitialSegments) or
      operationValue < 0 or operationValue > int64(MaxOperations): return -1
  let initialCount = int(initialValue)
  let operationCount = int(operationValue)

  var tree: SegmentLiChao
  var position = 2
  for _ in 0 ..< initialCount:
    if int(length) - position < 4: return -1
    let left = values[position]
    let right = values[position + 1]
    let slope = values[position + 2]
    let intercept = values[position + 3]
    if not validSegment(left, right, slope, intercept): return -1
    addSegment(tree, 1, DomainLow, DomainHigh, left, right, slope, intercept)
    position += 4

  var checksum = 0'i64
  var queryNumber = 0'i64
  for _ in 0 ..< operationCount:
    if position >= int(length): return -1
    let opcode = values[position]
    inc position
    if opcode == 0:
      if int(length) - position < 4: return -1
      let left = values[position]
      let right = values[position + 1]
      let slope = values[position + 2]
      let intercept = values[position + 3]
      if not validSegment(left, right, slope, intercept): return -1
      addSegment(tree, 1, DomainLow, DomainHigh, left, right, slope, intercept)
      position += 4
    elif opcode == 1:
      if position >= int(length): return -1
      let x = values[position]
      inc position
      if x < DomainLow or x > DomainHigh: return -1
      let answer = minimumAt(tree, 1, DomainLow, DomainHigh, x)
      inc queryNumber
      checksum += queryNumber * (answer + ChecksumOffset)
    else:
      return -1
  if position != int(length): return -1
  checksum
