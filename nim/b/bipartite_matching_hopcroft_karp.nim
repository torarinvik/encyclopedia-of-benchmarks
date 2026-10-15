## Hopcroft-Karp maximum cardinality matching for a bounded bipartite graph.
const MaxSide = 64
const MaxEdges = MaxSide * MaxSide
const InfDistance = 1_000_000

proc dfsAugment(left, rightCount: int, adjacency: openArray[bool],
    distance: var array[MaxSide, int], nilDistance: int,
    pairLeft, pairRight: var array[MaxSide, int]): bool =
  for right in 0 ..< rightCount:
    if not adjacency[left * MaxSide + right]: continue
    let mate = pairRight[right]
    if mate < 0:
      if distance[left] + 1 != nilDistance: continue
      pairLeft[left] = right
      pairRight[right] = left
      return true
    if distance[mate] == distance[left] + 1 and
        dfsAugment(mate, rightCount, adjacency, distance, nilDistance, pairLeft, pairRight):
      pairLeft[left] = right
      pairRight[right] = left
      return true
  distance[left] = InfDistance
  false

proc bfsLayers(leftCount, rightCount: int, adjacency: openArray[bool],
    pairRight: array[MaxSide, int], distance: var array[MaxSide, int]): int =
  var queue: array[MaxSide, int]
  var head = 0
  var tail = 0
  for left in 0 ..< leftCount:
    if distance[left] == 0:
      queue[tail] = left
      inc tail
  var nilDistance = InfDistance
  while head < tail:
    let left = queue[head]
    inc head
    if distance[left] + 1 > nilDistance: continue
    for right in 0 ..< rightCount:
      if not adjacency[left * MaxSide + right]: continue
      let mate = pairRight[right]
      if mate < 0:
        nilDistance = min(nilDistance, distance[left] + 1)
      elif distance[mate] < 0:
        distance[mate] = distance[left] + 1
        queue[tail] = mate
        inc tail
  nilDistance

proc bipartite_matching_hopcroft_karp*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bipartite_matching_hopcroft_karp".} =
  if input == nil or length < 3: return -1
  let leftValue = input[0]
  let rightValue = input[1]
  let edgeValue = input[2]
  if leftValue < 0 or leftValue > MaxSide or rightValue < 0 or rightValue > MaxSide or
      edgeValue < 0 or edgeValue > MaxEdges: return -1
  let leftCount = int(leftValue)
  let rightCount = int(rightValue)
  let edgeCount = int(edgeValue)
  if int(length) != 3 + 2 * edgeCount: return -1
  var adjacency: array[MaxSide * MaxSide, bool]
  for edge in 0 ..< edgeCount:
    let left = input[3 + 2 * edge]
    let right = input[4 + 2 * edge]
    if left < 0 or left >= leftValue or right < 0 or right >= rightValue: return -1
    adjacency[int(left) * MaxSide + int(right)] = true
  var pairLeft: array[MaxSide, int]
  var pairRight: array[MaxSide, int]
  var distance: array[MaxSide, int]
  for left in 0 ..< leftCount: pairLeft[left] = -1
  for right in 0 ..< rightCount: pairRight[right] = -1
  var matching = 0'i64
  while true:
    for left in 0 ..< leftCount:
      distance[left] = if pairLeft[left] < 0: 0 else: -1
    let nilDistance = bfsLayers(leftCount, rightCount, adjacency, pairRight, distance)
    if nilDistance == InfDistance: break
    for left in 0 ..< leftCount:
      if pairLeft[left] < 0 and dfsAugment(left, rightCount, adjacency, distance,
          nilDistance, pairLeft, pairRight):
        inc matching
  matching
