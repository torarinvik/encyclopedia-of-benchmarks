const MaxN = 64
const MaxNode = 2 * MaxN - 1
const MaxInput = MaxN + 2
const MaxWeight = 1_000_000'i64
const GwInfinity = 1'i64 shl 62

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc garsia_wachs_alphabetic_tree*(input: ptr UncheckedArray[int64], inputLength: csize_t,
                    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
                    {.cdecl, exportc: "garsia_wachs_alphabetic_tree".} =
  if input == nil or inputLength < 2 or inputLength > MaxInput.csize_t: return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN.int64: return -1
  let n = int(nValue)
  if int(inputLength) != n + 1: return -1

  var nodeWeight: array[MaxNode, int64]
  var left, right: array[MaxNode, int]
  var active: array[MaxN, int]
  for i in 0..<n:
    if input[i + 1] < 0 or input[i + 1] > MaxWeight: return -1
    nodeWeight[i] = input[i + 1]
    left[i] = -1
    right[i] = -1
    active[i] = i
  var activeCount = n
  var nextNode = n
  while activeCount > 1:
    var pair = 0
    while pair + 1 < activeCount:
      let following = if pair + 2 < activeCount: nodeWeight[active[pair + 2]] else: GwInfinity
      if nodeWeight[active[pair]] <= following: break
      inc pair
    let first = active[pair]
    let second = active[pair + 1]
    let combined = nodeWeight[first] + nodeWeight[second]
    nodeWeight[nextNode] = combined
    left[nextNode] = first
    right[nextNode] = second
    var earlier = pair
    while earlier > 0 and nodeWeight[active[earlier - 1]] < combined: dec earlier
    let insertAt = earlier
    for i in pair ..< activeCount - 2: active[i] = active[i + 2]
    activeCount -= 2
    for i in countdown(activeCount, insertAt + 1): active[i] = active[i - 1]
    active[insertAt] = nextNode
    inc activeCount
    inc nextNode

  var depths: array[MaxN, int]
  var stackNode: array[2 * MaxN, int]
  var stackDepth: array[2 * MaxN, int]
  var top = 1
  stackNode[0] = active[0]
  while top > 0:
    dec top
    let node = stackNode[top]
    let depth = stackDepth[top]
    if node < n:
      depths[node] = depth
    else:
      stackNode[top] = right[node]
      stackDepth[top] = depth + 1
      inc top
      stackNode[top] = left[node]
      stackDepth[top] = depth + 1
      inc top

  var orderedLeft, orderedRight: array[MaxNode, int]
  var codeNode: array[2 * MaxN, int]
  var codeDepth: array[2 * MaxN, int]
  var codeTop = 0
  var nextOrdered = n
  for leaf in 0..<n:
    codeNode[codeTop] = leaf
    codeDepth[codeTop] = depths[leaf]
    inc codeTop
    while codeTop >= 2 and codeDepth[codeTop - 1] == codeDepth[codeTop - 2]:
      let level = codeDepth[codeTop - 1]
      if level <= 0 or nextOrdered >= 2 * n - 1: return -1
      orderedLeft[nextOrdered] = codeNode[codeTop - 2]
      orderedRight[nextOrdered] = codeNode[codeTop - 1]
      codeTop -= 2
      codeNode[codeTop] = nextOrdered
      codeDepth[codeTop] = level - 1
      inc codeTop
      inc nextOrdered
  if codeTop != 1 or codeDepth[0] != 0 or nextOrdered != 2 * n - 1: return -1

  var cost = 0'i64
  for i in 0..<n: cost += input[i + 1] * int64(depths[i])
  let outputBytes = 8 * (n + 1)
  if output == nil or int(outputCapacity) < outputBytes: return -2
  putI64(output, 0, cost)
  for i in 0..<n: putI64(output, 8 * (i + 1), int64(depths[i]))
  int64(outputBytes)
