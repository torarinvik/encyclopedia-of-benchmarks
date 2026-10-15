## Kuhn DFS augmenting-path maximum matching for a bounded bipartite graph.
const MaxSide = 64
const MaxEdges = MaxSide * MaxSide

proc tryAugment(left, rightCount: int, adjacency: openArray[bool],
    seenRight: var array[MaxSide, bool], pairRight: var array[MaxSide, int]): bool =
  for right in 0 ..< rightCount:
    if not adjacency[left * MaxSide + right] or seenRight[right]: continue
    seenRight[right] = true
    let mate = pairRight[right]
    if mate < 0 or tryAugment(mate, rightCount, adjacency, seenRight, pairRight):
      pairRight[right] = left
      return true
  false

proc bipartite_matching_kuhn*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bipartite_matching_kuhn".} =
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
  var pairRight: array[MaxSide, int]
  for right in 0 ..< rightCount: pairRight[right] = -1
  var matching = 0'i64
  for left in 0 ..< leftCount:
    var seenRight: array[MaxSide, bool]
    if tryAugment(left, rightCount, adjacency, seenRight, pairRight): inc matching
  matching
