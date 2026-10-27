const MaxLeaves = 8
const MaxNodes = 15
const MaxCandidates = 256
const MaxInput = 32
const OutputBytes = 32

type
  Candidate = object
    height, width: int64
    mask: uint64
  Node = object
    op, left, right: int
    cellHeight, cellWidth: int64
    leafIndex, count: int
    candidates: array[MaxCandidates, Candidate]

proc maskLexLess(a, b: uint64, leaves: int): bool =
  for bit in 0 ..< leaves:
    let av = (a shr bit) and 1'u64
    let bv = (b shr bit) and 1'u64
    if av != bv: return av < bv
  false

proc prune(node: var Node, leaves: int) =
  var dominated: array[MaxCandidates, bool]
  for i in 0 ..< node.count:
    let a = node.candidates[i]
    for j in 0 ..< node.count:
      if i == j: continue
      let b = node.candidates[j]
      if b.height <= a.height and b.width <= a.width:
        if b.height < a.height or b.width < a.width or
            maskLexLess(b.mask, a.mask, leaves) or (b.mask == a.mask and j < i):
          dominated[i] = true
          break
  var kept = 0
  for i in 0 ..< node.count:
    if not dominated[i]:
      node.candidates[kept] = node.candidates[i]
      inc kept
  node.count = kept

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc slicing_floorplan_stockmeyer*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "slicing_floorplan_stockmeyer".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxInput): return -1
  if input[0] < 1 or input[0] > int64(MaxLeaves): return -1
  let leaves = int(input[0])
  var nodes: array[MaxNodes, Node]
  var stack: array[MaxNodes, int]
  var stackSize = 0
  var nodeCount = 0
  var leafCount = 0
  var internalCount = 0
  var position = 1
  while position < int(length):
    let token = input[position]
    inc position
    if token == 2:
      if position + 2 > int(length) or leafCount >= leaves or nodeCount >= MaxNodes: return -1
      let height = input[position]
      let width = input[position + 1]
      position += 2
      if height < 1 or height > 20 or width < 1 or width > 20: return -1
      nodes[nodeCount].op = 2
      nodes[nodeCount].cellHeight = height
      nodes[nodeCount].cellWidth = width
      nodes[nodeCount].leafIndex = leafCount
      nodes[nodeCount].candidates[0] = Candidate(height: height, width: width, mask: 0)
      nodes[nodeCount].candidates[1] = Candidate(height: width, width: height, mask: 1'u64 shl leafCount)
      nodes[nodeCount].count = 2
      prune(nodes[nodeCount], leaves)
      stack[stackSize] = nodeCount
      inc stackSize
      inc nodeCount
      inc leafCount
    elif token == 0 or token == 1:
      if stackSize < 2 or internalCount >= leaves - 1 or nodeCount >= MaxNodes: return -1
      dec stackSize
      let rightNode = stack[stackSize]
      dec stackSize
      let leftNode = stack[stackSize]
      if nodes[rightNode].op == int(token): return -1
      nodes[nodeCount].op = int(token)
      nodes[nodeCount].left = leftNode
      nodes[nodeCount].right = rightNode
      for i in 0 ..< nodes[leftNode].count:
        for j in 0 ..< nodes[rightNode].count:
          if nodes[nodeCount].count >= MaxCandidates: return -1
          let a = nodes[leftNode].candidates[i]
          let b = nodes[rightNode].candidates[j]
          var c: Candidate
          c.mask = a.mask or b.mask
          if token == 0:
            c.height = max(a.height, b.height)
            c.width = a.width + b.width
          else:
            c.height = a.height + b.height
            c.width = max(a.width, b.width)
          nodes[nodeCount].candidates[nodes[nodeCount].count] = c
          inc nodes[nodeCount].count
      prune(nodes[nodeCount], leaves)
      stack[stackSize] = nodeCount
      inc stackSize
      inc nodeCount
      inc internalCount
    else:
      return -1
  if position != int(length) or leafCount != leaves or internalCount != leaves - 1 or
      nodeCount != 2 * leaves - 1 or stackSize != 1: return -1
  let root = nodes[stack[0]]
  if root.count == 0: return -1
  var best = root.candidates[0]
  for i in 1 ..< root.count:
    let candidate = root.candidates[i]
    let area = candidate.height * candidate.width
    let bestArea = best.height * best.width
    if area < bestArea or (area == bestArea and (candidate.height < best.height or
        (candidate.height == best.height and (candidate.width < best.width or
        (candidate.width == best.width and maskLexLess(candidate.mask, best.mask, leaves)))))):
      best = candidate
  if output.isNil or capacity < csize_t(OutputBytes): return -2
  var staged: array[OutputBytes, uint8]
  storeI64Le(addr staged[0], 0, best.height * best.width)
  storeI64Le(addr staged[0], 8, best.height)
  storeI64Le(addr staged[0], 16, best.width)
  storeI64Le(addr staged[0], 24, int64(best.mask))
  for byte in 0 ..< OutputBytes: output[byte] = staged[byte]
  int64(OutputBytes)
