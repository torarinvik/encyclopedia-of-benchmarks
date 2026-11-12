const MaxN = 48
const MaxNodes = 2 * MaxN - 1
const Grid = MaxN * MaxN

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc intervalsOverlap(leftA, rightA, leftB, rightB: int): bool =
  (leftA < leftB and leftB <= rightA and rightA < rightB) or
  (leftB < leftA and leftA <= rightB and rightB < rightA)

proc common_interval_decomposition_tree*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "common_interval_decomposition_tree".} =
  if input.isNil or length < 2 or length > csize_t(1 + MaxN): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > int64(MaxN): return -1
  let n = int(nValue)
  if length != csize_t(n + 1): return -1

  var seen: array[MaxN, bool]
  for i in 0 ..< n:
    let value = input[i + 1]
    if value < 0 or value >= int64(n) or seen[int(value)]: return -1
    seen[int(value)] = true

  var connected: array[Grid, bool]
  var strong: array[Grid, bool]
  for left in 0 ..< n:
    var minimum = int64(n)
    var maximum = -1'i64
    for right in left ..< n:
      let value = input[right + 1]
      if value < minimum: minimum = value
      if value > maximum: maximum = value
      let slot = left * MaxN + right
      if maximum - minimum == int64(right - left):
        connected[slot] = true
        strong[slot] = true

  for leftA in 0 ..< n:
    for rightA in leftA ..< n:
      let slotA = leftA * MaxN + rightA
      if not connected[slotA]: continue
      for leftB in 0 ..< n:
        for rightB in leftB ..< n:
          let slotB = leftB * MaxN + rightB
          if slotB <= slotA or not connected[slotB]: continue
          if intervalsOverlap(leftA, rightA, leftB, rightB):
            strong[slotA] = false
            strong[slotB] = false

  var nodeLeft: array[MaxNodes, int]
  var nodeRight: array[MaxNodes, int]
  var parent: array[MaxNodes, int]
  var nodeType: array[MaxNodes, int]
  var nodeCount = 0
  for span in countdown(n, 1):
    for left in 0 .. n - span:
      let right = left + span - 1
      if not strong[left * MaxN + right]: continue
      nodeLeft[nodeCount] = left
      nodeRight[nodeCount] = right
      inc nodeCount
  if nodeCount == 0 or nodeCount > MaxNodes: return -1

  for node in 0 ..< nodeCount:
    let span = nodeRight[node] - nodeLeft[node] + 1
    var bestSpan = n + 1
    parent[node] = -1
    for candidate in 0 ..< nodeCount:
      let candidateSpan = nodeRight[candidate] - nodeLeft[candidate] + 1
      if candidateSpan > span and candidateSpan < bestSpan and
          nodeLeft[candidate] <= nodeLeft[node] and
          nodeRight[node] <= nodeRight[candidate]:
        parent[node] = candidate
        bestSpan = candidateSpan

  for node in 0 ..< nodeCount:
    var children: array[MaxN, int]
    var childCount = 0
    for child in 0 ..< nodeCount:
      if parent[child] != node: continue
      var at = childCount
      while at > 0 and nodeLeft[children[at - 1]] > nodeLeft[child]:
        children[at] = children[at - 1]
        dec at
      children[at] = child
      inc childCount

    for first in 0 ..< childCount:
      for last in first ..< childCount:
        let left = nodeLeft[children[first]]
        let right = nodeRight[children[last]]
        var minimum = int64(n)
        var maximum = -1'i64
        for position in left .. right:
          let value = input[position + 1]
          if value < minimum: minimum = value
          if value > maximum: maximum = value
        if maximum - minimum != int64(right - left):
          nodeType[node] = 1
          break
      if nodeType[node] != 0: break

  let outputBytes = (1 + 4 * nodeCount) * 8
  if output.isNil or capacity < csize_t(outputBytes): return -2
  storeI64Le(output, 0, int64(nodeCount))
  for node in 0 ..< nodeCount:
    let offset = 8 + 32 * node
    storeI64Le(output, offset, int64(parent[node]))
    storeI64Le(output, offset + 8, int64(nodeLeft[node]))
    storeI64Le(output, offset + 16, int64(nodeRight[node]))
    storeI64Le(output, offset + 24, int64(nodeType[node]))
  int64(outputBytes)
