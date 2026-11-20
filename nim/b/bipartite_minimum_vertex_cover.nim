## Ordered augmenting-path matching and canonical minimum-cover certificate.
const MaxSide = 8
const MaxVertices = 2 * MaxSide
const MaxParseableInput = MaxSide + 3

proc augmentLeft(left, leftCount, rightCount: int, rows: openArray[uint16],
    states: openArray[int], matchRight: var array[MaxSide, int],
    seen: var array[MaxSide, bool]): bool =
  for right in 0 ..< rightCount:
    if (rows[left] and (1'u16 shl right)) == 0 or seen[right] or states[leftCount + right] != -1: continue
    seen[right] = true
    let owner = matchRight[right]
    if owner < 0 or augmentLeft(owner, leftCount, rightCount, rows, states, matchRight, seen):
      matchRight[right] = left
      return true
  false

proc maximumMatching(leftCount, rightCount: int, rows: openArray[uint16],
    states: openArray[int], matchRight: var array[MaxSide, int]): int =
  for right in 0 ..< rightCount: matchRight[right] = -1
  var size = 0
  for left in 0 ..< leftCount:
    if states[left] != -1: continue
    var seen: array[MaxSide, bool]
    if augmentLeft(left, leftCount, rightCount, rows, states, matchRight, seen): inc size
  size

proc bitCount(valueInput: uint32): int =
  var value = valueInput
  var count = 0
  while value != 0'u32:
    count += int(value and 1'u32)
    value = value shr 1
  count

proc alternatingCover(leftCount, rightCount: int, rows: openArray[uint16],
    matchRight: openArray[int]): uint32 =
  var matchedLeft, reachedLeft, reachedRight: array[MaxSide, bool]
  var queue: array[MaxSide, int]
  var head = 0
  var tail = 0
  for right in 0 ..< rightCount:
    if matchRight[right] >= 0: matchedLeft[matchRight[right]] = true
  for left in 0 ..< leftCount:
    if not matchedLeft[left]:
      reachedLeft[left] = true
      queue[tail] = left
      inc tail
  while head < tail:
    let left = queue[head]
    inc head
    for right in 0 ..< rightCount:
      if (rows[left] and (1'u16 shl right)) == 0 or reachedRight[right] or matchRight[right] < 0: continue
      reachedRight[right] = true
      let owner = matchRight[right]
      if not reachedLeft[owner]:
        reachedLeft[owner] = true
        queue[tail] = owner
        inc tail
  var result = 0'u32
  for left in 0 ..< leftCount:
    if not reachedLeft[left]: result = result or (1'u32 shl left)
  for right in 0 ..< rightCount:
    if reachedRight[right]: result = result or (1'u32 shl (leftCount + right))
  result

proc minimumCompletionSize(leftCount, rightCount: int, rows: openArray[uint16],
    inputStates: openArray[int]): int =
  var states: array[MaxVertices, int]
  let total = leftCount + rightCount
  for i in 0 ..< total: states[i] = inputStates[i]
  var changed = true
  while changed:
    changed = false
    for left in 0 ..< leftCount:
      for right in 0 ..< rightCount:
        if (rows[left] and (1'u16 shl right)) == 0: continue
        let rightVertex = leftCount + right
        if states[left] == 0 and states[rightVertex] == 0: return -1
        if states[left] == 0 and states[rightVertex] == -1:
          states[rightVertex] = 1
          changed = true
        elif states[rightVertex] == 0 and states[left] == -1:
          states[left] = 1
          changed = true
  var forcedIn = 0
  for i in 0 ..< total:
    if states[i] == 1: inc forcedIn
  var residualMatch: array[MaxSide, int]
  forcedIn + maximumMatching(leftCount, rightCount, rows, states, residualMatch)

proc canonicalCover(leftCount, rightCount: int, rows: openArray[uint16], optimum: int): uint32 =
  var states: array[MaxVertices, int]
  let total = leftCount + rightCount
  for i in 0 ..< total: states[i] = -1
  for vertex in 0 ..< total:
    states[vertex] = 0
    if minimumCompletionSize(leftCount, rightCount, rows, states) != optimum: states[vertex] = 1
  var result = 0'u32
  for vertex in 0 ..< total:
    if states[vertex] == 1: result = result or (1'u32 shl vertex)
  result

proc bipartite_minimum_vertex_cover*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bipartite_minimum_vertex_cover".} =
  if input == nil or length < csize_t(2) or length > csize_t(MaxParseableInput): return -1
  let leftValue = input[0]
  let rightValue = input[1]
  if leftValue < 0 or leftValue > MaxSide.int64 or rightValue < 0 or rightValue > MaxSide.int64: return -1
  let leftCount = int(leftValue)
  let rightCount = int(rightValue)
  if int(length) != leftCount + 2: return -1
  let rightDomain = (1'i64 shl rightCount) - 1
  var rows: array[MaxSide, uint16]
  for left in 0 ..< leftCount:
    let row = input[2 + left]
    if row < 0 or (row and not rightDomain) != 0: return -1
    rows[left] = uint16(row)
  var freeStates: array[MaxVertices, int]
  for i in 0 ..< leftCount + rightCount: freeStates[i] = -1
  var matchRight: array[MaxSide, int]
  let matchingSize = maximumMatching(leftCount, rightCount, rows, freeStates, matchRight)
  let optimum = bitCount(alternatingCover(leftCount, rightCount, rows, matchRight))
  if optimum != matchingSize: return -1
  int64(canonicalCover(leftCount, rightCount, rows, optimum))
