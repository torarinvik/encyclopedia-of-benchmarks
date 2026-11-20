const
  Side = 6
  MaxVertices = 12
  MaxEdges = 36
  MaxParseableLength = 76

proc dmAugment(left, rightCount: int, adjacency: array[Side, uint16],
               seen: var array[Side, bool], matchRight: var array[Side, int]): bool =
  for right in 0 ..< rightCount:
    let bit = uint16(1 shl right)
    if (adjacency[left] and bit) == 0 or seen[right]: continue
    seen[right] = true
    let mate = matchRight[right]
    if mate < 0 or dmAugment(mate, rightCount, adjacency, seen, matchRight):
      matchRight[right] = left
      return true
  false

proc dmMatching(leftCount, rightCount: int, adjacency: array[Side, uint16],
                matchLeft: var array[Side, int], matchRight: var array[Side, int]): int =
  for right in 0 ..< Side: matchRight[right] = -1
  for left in 0 ..< leftCount:
    var seen: array[Side, bool]
    if dmAugment(left, rightCount, adjacency, seen, matchRight): inc result
  for left in 0 ..< Side: matchLeft[left] = -1
  for right in 0 ..< rightCount:
    if matchRight[right] >= 0: matchLeft[matchRight[right]] = right

proc dulmage_mendelsohn_decomposition*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "dulmage_mendelsohn_decomposition".} =
  if input == nil or length < 3 or length > csize_t(MaxParseableLength): return -1
  let left64 = input[0]
  let right64 = input[1]
  let edges64 = input[2]
  if left64 < 0 or left64 > Side.int64 or right64 < 0 or right64 > Side.int64 or
      left64 + right64 < 1 or edges64 < 0 or edges64 > MaxEdges.int64 or
      edges64 > left64 * right64: return -1
  let leftCount = int(left64)
  let rightCount = int(right64)
  let total = leftCount + rightCount
  let edgeCount = int(edges64)
  if int(length) != 3 + 2*edgeCount: return -1
  var adjacency: array[Side, uint16]
  var global: array[MaxVertices, uint16]
  for edge in 0 ..< edgeCount:
    let u64 = input[3 + 2*edge]
    let v64 = input[4 + 2*edge]
    if u64 < 0 or u64 >= left64 or v64 < 0 or v64 >= right64: return -1
    let u = int(u64)
    let v = int(v64)
    let rightVertex = leftCount + v
    let bit = uint16(1 shl v)
    if (adjacency[u] and bit) != 0: return -1
    adjacency[u] = adjacency[u] or bit
    global[u] = global[u] or uint16(1 shl rightVertex)
    global[rightVertex] = global[rightVertex] or uint16(1 shl u)

  var matchLeft, matchRight: array[Side, int]
  let matchingSize = dmMatching(leftCount, rightCount, adjacency, matchLeft, matchRight)
  var seen: array[2*MaxVertices, bool]
  var queue: array[2*MaxVertices, int]
  var head = 0
  var tail = 0
  for left in 0 ..< leftCount:
    if matchLeft[left] < 0:
      let state = 2*left
      seen[state] = true
      queue[tail] = state
      inc tail
  for right in 0 ..< rightCount:
    if matchRight[right] < 0:
      let state = 2*(leftCount + right)
      seen[state] = true
      queue[tail] = state
      inc tail
  while head < tail:
    let state = queue[head]
    inc head
    let vertex = state div 2
    let parity = state mod 2
    for neighbor in 0 ..< total:
      if (global[vertex] and uint16(1 shl neighbor)) == 0: continue
      let matched = if vertex < leftCount:
        matchLeft[vertex] == neighbor - leftCount
      else:
        matchRight[vertex - leftCount] == neighbor
      if (parity == 0 and matched) or (parity == 1 and not matched): continue
      let nextState = 2*neighbor + 1 - parity
      if not seen[nextState]:
        seen[nextState] = true
        queue[tail] = nextState
        inc tail

  var packed = int64(matchingSize) shl 32
  for vertex in 0 ..< total:
    let code = if seen[2*vertex]: 0 elif seen[2*vertex + 1]: 1 else: 2
    packed = packed or (int64(code) shl (2*vertex))
  packed
