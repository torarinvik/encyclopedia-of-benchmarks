## Minimum edge coloring of a bounded bipartite multigraph.
import std/ffi

const MaxSide = 5
const MaxEdges = 10
const MaxInputLength = 23
const MaxOutputBytes = 88
type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]
  Matrix = array[MaxSide * MaxSide, int]

proc augment(left, side: int, multiplicity: Matrix,
    seen: var array[MaxSide, bool], matchRight: var array[MaxSide, int]): bool =
  for right in 0 ..< side:
    let index = left * MaxSide + right
    if multiplicity[index] == 0 or seen[right]: continue
    seen[right] = true
    let mate = matchRight[right]
    if mate < 0 or augment(mate, side, multiplicity, seen, matchRight):
      matchRight[right] = left
      return true
  false

proc storeU64Le(output: var array[MaxOutputBytes, uint8], offset: int, value: uint64) =
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((value shr (byte * 8)) and 0xff'u64)

proc bipartite_edge_coloring*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "bipartite_edge_coloring".} =
  if input == nil or int(length) < 3 or int(length) > MaxInputLength: return -1
  let leftValue = input[0]
  let rightValue = input[1]
  let edgeValue = input[2]
  if leftValue < 1 or leftValue > MaxSide or rightValue < 1 or rightValue > MaxSide or
      edgeValue < 1 or edgeValue > MaxEdges: return -1
  let leftCount = int(leftValue)
  let rightCount = int(rightValue)
  let edgeCount = int(edgeValue)
  if int(length) != 3 + 2 * edgeCount: return -1

  var multiplicity: Matrix
  var originalRemaining: Matrix
  var leftDegree: array[MaxSide, int]
  var rightDegree: array[MaxSide, int]
  var edgeLeft: array[MaxEdges, int]
  var edgeRight: array[MaxEdges, int]
  for edge in 0 ..< edgeCount:
    let left = input[3 + 2 * edge]
    let right = input[4 + 2 * edge]
    if left < 0 or left >= leftValue or right < 0 or right >= rightValue: return -1
    let u = int(left)
    let v = int(right)
    edgeLeft[edge] = u
    edgeRight[edge] = v
    inc multiplicity[u * MaxSide + v]
    inc originalRemaining[u * MaxSide + v]
    inc leftDegree[u]
    inc rightDegree[v]

  let side = max(leftCount, rightCount)
  var maximumDegree = 0
  for vertex in 0 ..< side:
    maximumDegree = max(maximumDegree, max(leftDegree[vertex], rightDegree[vertex]))
  while true:
    var left = 0
    while left < side and leftDegree[left] == maximumDegree: inc left
    if left == side: break
    var right = 0
    while right < side and rightDegree[right] == maximumDegree: inc right
    if right == side: return -1
    inc multiplicity[left * MaxSide + right]
    inc leftDegree[left]
    inc rightDegree[right]

  var colors: array[MaxEdges, int]
  for edge in 0 ..< edgeCount: colors[edge] = -1
  for color in 0 ..< maximumDegree:
    var matchRight: array[MaxSide, int]
    for right in 0 ..< side: matchRight[right] = -1
    for left in 0 ..< side:
      var seen: array[MaxSide, bool]
      if not augment(left, side, multiplicity, seen, matchRight): return -1
    for right in 0 ..< side:
      let left = matchRight[right]
      if left < 0: return -1
      let index = left * MaxSide + right
      if originalRemaining[index] > 0:
        var edge = 0
        while edge < edgeCount and
            (colors[edge] >= 0 or edgeLeft[edge] != left or edgeRight[edge] != right): inc edge
        if edge == edgeCount: return -1
        colors[edge] = color
        dec originalRemaining[index]
      dec multiplicity[index]

  let bytes = 8 * (edgeCount + 1)
  if output == nil or int(outputCapacity) < bytes: return -2
  var staged: array[MaxOutputBytes, uint8]
  storeU64Le(staged, 0, uint64(maximumDegree))
  for edge in 0 ..< edgeCount:
    storeU64Le(staged, 8 * (edge + 1), uint64(colors[edge]))
  for byte in 0 ..< bytes: output[byte] = staged[byte]
  int64(bytes)
