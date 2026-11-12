const MaxN = 16
const MaxQ = 32
const MaxTokens = MaxN + 2 * (MaxN - 1 + MaxQ)
const MaxInput = 3 * MaxN + 5 * MaxQ + 1
const MaxDelta = 1000'i64

type
  TourNode = object
    left, right, parent: int32
    priority: uint32
    sequenceSize, markerCount: int
    marker: bool
    ownValue, sum, lazyAdd: int64
  EulerTour = object
    nodes: array[MaxTokens, TourNode]
    nextNode: int
    randomState: uint32

proc seqSize(tour: var EulerTour, id: int32): int =
  if id < 0: return 0
  tour.nodes[int(id)].sequenceSize
proc markerCount(tour: var EulerTour, id: int32): int =
  if id < 0: return 0
  tour.nodes[int(id)].markerCount
proc nodeSum(tour: var EulerTour, id: int32): int64 =
  if id < 0: return 0
  tour.nodes[int(id)].sum
proc pull(tour: var EulerTour, id: int32) =
  let i = int(id)
  let n = tour.nodes[i]
  tour.nodes[i].sequenceSize = 1 + seqSize(tour, n.left) + seqSize(tour, n.right)
  tour.nodes[i].markerCount = ord(n.marker) + markerCount(tour, n.left) + markerCount(tour, n.right)
  tour.nodes[i].sum = n.ownValue + nodeSum(tour, n.left) + nodeSum(tour, n.right)
proc applyAdd(tour: var EulerTour, id: int32, delta: int64) =
  if id < 0: return
  let i = int(id)
  if tour.nodes[i].markerCount == 0: return
  tour.nodes[i].sum += delta * int64(tour.nodes[i].markerCount)
  if tour.nodes[i].marker: tour.nodes[i].ownValue += delta
  tour.nodes[i].lazyAdd += delta
proc push(tour: var EulerTour, id: int32) =
  let i = int(id)
  let delta = tour.nodes[i].lazyAdd
  if delta == 0: return
  let left = tour.nodes[i].left
  let right = tour.nodes[i].right
  applyAdd(tour, left, delta)
  applyAdd(tour, right, delta)
  tour.nodes[i].lazyAdd = 0
proc nextPriority(tour: var EulerTour): uint32 =
  var x = tour.randomState
  x = x xor (x shl 13)
  x = x xor (x shr 17)
  x = x xor (x shl 5)
  tour.randomState = x
  x
proc newNode(tour: var EulerTour, marker: bool, value: int64): int32 =
  if tour.nextNode >= MaxTokens: return -1
  let id = tour.nextNode
  inc tour.nextNode
  tour.nodes[id] = TourNode(
    left: -1, right: -1, parent: -1, priority: nextPriority(tour),
    sequenceSize: 1, markerCount: ord(marker), marker: marker,
    ownValue: (if marker: value else: 0), sum: (if marker: value else: 0), lazyAdd: 0)
  int32(id)
proc split(tour: var EulerTour, root: int32, count: int): tuple[first, second: int32] =
  if root < 0: return (-1'i32, -1'i32)
  push(tour, root)
  let i = int(root)
  tour.nodes[i].parent = -1
  let left = tour.nodes[i].left
  if seqSize(tour, left) >= count:
    let (first, middle) = split(tour, left, count)
    tour.nodes[i].left = middle
    if middle >= 0: tour.nodes[int(middle)].parent = root
    pull(tour, root)
    if first >= 0: tour.nodes[int(first)].parent = -1
    tour.nodes[i].parent = -1
    return (first, root)
  let right = tour.nodes[i].right
  let (middle, second) = split(tour, right, count - seqSize(tour, left) - 1)
  tour.nodes[i].right = middle
  if middle >= 0: tour.nodes[int(middle)].parent = root
  pull(tour, root)
  tour.nodes[i].parent = -1
  if second >= 0: tour.nodes[int(second)].parent = -1
  (root, second)
proc merge(tour: var EulerTour, first, second: int32): int32 =
  if first < 0:
    if second >= 0: tour.nodes[int(second)].parent = -1
    return second
  if second < 0:
    tour.nodes[int(first)].parent = -1
    return first
  tour.nodes[int(first)].parent = -1
  tour.nodes[int(second)].parent = -1
  if tour.nodes[int(first)].priority >= tour.nodes[int(second)].priority:
    push(tour, first)
    let child = tour.nodes[int(first)].right
    let joined = merge(tour, child, second)
    tour.nodes[int(first)].right = joined
    if joined >= 0: tour.nodes[int(joined)].parent = first
    pull(tour, first)
    tour.nodes[int(first)].parent = -1
    return first
  push(tour, second)
  let child = tour.nodes[int(second)].left
  let joined = merge(tour, first, child)
  tour.nodes[int(second)].left = joined
  if joined >= 0: tour.nodes[int(joined)].parent = second
  pull(tour, second)
  tour.nodes[int(second)].parent = -1
  second
proc rootOf(tour: var EulerTour, start: int32): int32 =
  var id = start
  while tour.nodes[int(id)].parent >= 0: id = tour.nodes[int(id)].parent
  id
proc rankOf(tour: var EulerTour, start: int32): int =
  var id = start
  var rank = seqSize(tour, tour.nodes[int(id)].left)
  while tour.nodes[int(id)].parent >= 0:
    let parent = tour.nodes[int(id)].parent
    if tour.nodes[int(parent)].right == id:
      rank += 1 + seqSize(tour, tour.nodes[int(parent)].left)
    id = parent
  rank
proc rotateTo(tour: var EulerTour, id: int32): int32 =
  let root = rootOf(tour, id)
  let (first, second) = split(tour, root, rankOf(tour, id))
  merge(tour, second, first)
proc linkTours(tour: var EulerTour, markers: array[MaxN, int32], u, v: int,
               uv, vu: var int32): bool =
  let rootU = rootOf(tour, markers[u])
  let rootV = rootOf(tour, markers[v])
  if rootU == rootV: return false
  let (a0, a1) = split(tour, rootU, rankOf(tour, markers[u]) + 1)
  let (b0, bTail) = split(tour, rootV, rankOf(tour, markers[v]))
  let (vm, b1) = split(tour, bTail, 1)
  uv = newNode(tour, false, 0)
  vu = newNode(tour, false, 0)
  if uv < 0 or vu < 0: return false
  var root = merge(tour, a0, uv)
  root = merge(tour, root, b1)
  root = merge(tour, root, b0)
  root = merge(tour, root, vm)
  root = merge(tour, root, vu)
  discard merge(tour, root, a1)
  true
proc cutTours(tour: var EulerTour, uv, vu: int32): bool =
  let root = rotateTo(tour, uv)
  let reverseRank = rankOf(tour, vu)
  if reverseRank == 0: return false
  let (first, rest) = split(tour, root, 1)
  let (_, tail) = split(tour, rest, reverseRank - 1)
  let (reverse, _) = split(tour, tail, 1)
  if first != uv or reverse != vu: return false
  tour.nodes[int(uv)].left = -1; tour.nodes[int(uv)].right = -1; tour.nodes[int(uv)].parent = -1
  tour.nodes[int(vu)].left = -1; tour.nodes[int(vu)].right = -1; tour.nodes[int(vu)].parent = -1
  true
proc sideOperation(tour: var EulerTour, uv, vu: int32, update: bool,
                   delta: int64, answer: var int64): bool =
  let root = rotateTo(tour, uv)
  let reverseRank = rankOf(tour, vu)
  if reverseRank == 0: return false
  let (edge, rest) = split(tour, root, 1)
  let (side, tail) = split(tour, rest, reverseRank - 1)
  if edge != uv or side < 0: return false
  if update: applyAdd(tour, side, delta)
  else: answer = nodeSum(tour, side)
  let joined = merge(tour, edge, side)
  discard merge(tour, joined, tail)
  true

proc connected(adjacency: var array[MaxN * MaxN, bool], n, start, goal: int): bool =
  var seen: array[MaxN, bool]
  var queue: array[MaxN, int]
  var head = 0
  var tail = 1
  queue[0] = start
  seen[start] = true
  while head < tail:
    let u = queue[head]
    inc head
    if u == goal: return true
    for v in 0..<n:
      if adjacency[u * MaxN + v] and not seen[v]:
        seen[v] = true
        queue[tail] = v
        inc tail
  false
proc validateFields(input: ptr UncheckedArray[int64], n, q: int, queries: var int): bool =
  for i in 0..<n:
    if input[2 + i] < 0 or input[2 + i] > MaxDelta: return false
  let edgeStart = 2 + n
  for i in 0..<(n - 1):
    let u = input[edgeStart + 2 * i]
    let v = input[edgeStart + 2 * i + 1]
    if u < 0 or u >= n or v < 0 or v >= n or u == v: return false
  let operations = edgeStart + 2 * (n - 1)
  queries = 0
  for i in 0..<q:
    let at = operations + 5 * i
    let kind = input[at]; let v = input[at + 1]; let p = input[at + 2]
    let a = input[at + 3]; let b = input[at + 4]
    if kind == 0:
      if v < 0 or v >= n or p < 0 or p >= n or a < 0 or a >= n or b < 0 or b >= n or v == p or a == b: return false
    elif kind == 1:
      if v < 0 or v >= n or p < 0 or p >= n or v == p or a < 0 or a > MaxDelta or b != 0: return false
    elif kind == 2:
      if v < 0 or v >= n or p < 0 or p >= n or v == p or a != 0 or b != 0: return false
      inc queries
    else: return false
  true
proc validateTopology(input: ptr UncheckedArray[int64], n, q: int): bool =
  var adjacency: array[MaxN * MaxN, bool]
  let edgeStart = 2 + n
  let operations = edgeStart + 2 * (n - 1)
  for i in 0..<(n - 1):
    let u = int(input[edgeStart + 2 * i]); let v = int(input[edgeStart + 2 * i + 1])
    if adjacency[u * MaxN + v]: return false
    adjacency[u * MaxN + v] = true
    adjacency[v * MaxN + u] = true
  for v in 0..<n:
    if not connected(adjacency, n, 0, v): return false
  for i in 0..<q:
    let at = operations + 5 * i
    let kind = int(input[at]); let v = int(input[at + 1]); let p = int(input[at + 2])
    if kind == 0:
      let a = int(input[at + 3]); let b = int(input[at + 4])
      if not adjacency[v * MaxN + p]: return false
      adjacency[v * MaxN + p] = false; adjacency[p * MaxN + v] = false
      if connected(adjacency, n, a, b): return false
      adjacency[a * MaxN + b] = true; adjacency[b * MaxN + a] = true
    elif not adjacency[v * MaxN + p]: return false
  true
proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc dynamic_tree_subtree_add_subtree_sum*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "dynamic_tree_subtree_add_subtree_sum".} =
  if input == nil or inputLength < 2 or inputLength > MaxInput.csize_t: return -1
  let nValue = input[0]; let qValue = input[1]
  if nValue < 1 or nValue > MaxN.int64 or qValue < 0 or qValue > MaxQ.int64: return -1
  let n = int(nValue); let q = int(qValue)
  if int(inputLength) != 3 * n + 5 * q: return -1
  var queries = 0
  if not validateFields(input, n, q, queries) or not validateTopology(input, n, q): return -1
  let outputBytes = 8 * queries
  if outputBytes > 0 and (output == nil or int(outputCapacity) < outputBytes): return -2

  var tour: EulerTour
  tour.randomState = 0x9e3779b9'u32
  var markers: array[MaxN, int32]
  for i in 0..<n: markers[i] = newNode(tour, true, input[2 + i])
  var directed: array[MaxN * MaxN, int32]
  for i in 0..<directed.len: directed[i] = -1
  let edgeStart = 2 + n; let operations = edgeStart + 2 * (n - 1)
  for i in 0..<(n - 1):
    let u = int(input[edgeStart + 2 * i]); let v = int(input[edgeStart + 2 * i + 1])
    var uv, vu: int32
    if not linkTours(tour, markers, u, v, uv, vu): return -1
    directed[u * MaxN + v] = uv; directed[v * MaxN + u] = vu
  var answers: array[MaxQ, int64]
  var answerCount = 0
  for i in 0..<q:
    let at = operations + 5 * i
    let kind = int(input[at]); let v = int(input[at + 1]); let p = int(input[at + 2])
    if kind == 0:
      let a = int(input[at + 3]); let b = int(input[at + 4])
      let uv = directed[v * MaxN + p]; let vu = directed[p * MaxN + v]
      if uv < 0 or vu < 0 or not cutTours(tour, uv, vu): return -1
      directed[v * MaxN + p] = -1; directed[p * MaxN + v] = -1
      var newUv, newVu: int32
      if not linkTours(tour, markers, a, b, newUv, newVu): return -1
      directed[a * MaxN + b] = newUv; directed[b * MaxN + a] = newVu
    elif kind == 1:
      var ignored: int64 = 0
      if not sideOperation(tour, directed[p * MaxN + v], directed[v * MaxN + p], true, input[at + 3], ignored): return -1
    else:
      var answer: int64 = 0
      if not sideOperation(tour, directed[p * MaxN + v], directed[v * MaxN + p], false, 0, answer): return -1
      answers[answerCount] = answer
      inc answerCount
  for i in 0..<answerCount: putI64(output, 8 * i, answers[i])
  int64(outputBytes)
