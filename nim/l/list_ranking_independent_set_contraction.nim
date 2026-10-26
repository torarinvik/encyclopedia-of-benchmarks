const MaxN = 16
const MaxInput = 34
const MaxOutput = 128

proc list_ranking_independent_set_contraction*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "list_ranking_independent_set_contraction".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let head64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or int64(length) != 2 + 2 * n64 or
      head64 < 0 or head64 >= n64: return -1
  let n = int(n64)
  let head = int(head64)
  var weight: array[MaxN, int64]
  var successor: array[MaxN, int64]
  var indegree: array[MaxN, int]
  var tailCount = 0
  for node in 0 ..< n:
    weight[node] = input[2 + node]
    successor[node] = input[2 + n + node]
    if weight[node] < 1 or weight[node] > 10000 or successor[node] < -1 or
        successor[node] >= n64: return -1
    if successor[node] == -1:
      inc tailCount
    else:
      let next = int(successor[node])
      inc indegree[next]
      if indegree[next] > 1: return -1
  if tailCount != 1 or indegree[head] != 0: return -1

  var path: array[MaxN, int]
  var seen: array[MaxN, bool]
  var pathLength = 0
  var node = head64
  while node != -1:
    let index = int(node)
    if seen[index] or pathLength == n: return -1
    seen[index] = true
    path[pathLength] = index
    inc pathLength
    node = successor[index]
  if pathLength != n: return -1
  let outputBytes = 8 * n
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var removedNode, removedSuccessor: array[MaxN, int]
  var oldSuccessorWeight: array[MaxN, int64]
  var removedCount = 0
  while pathLength > 1:
    var counts: array[3, int]
    for position in 0 ..< (pathLength - 1):
      inc counts[position mod 3]
    var color = 0
    for candidate in 1 ..< 3:
      if counts[candidate] > counts[color]: color = candidate
    var write = 0
    for position in 0 ..< pathLength:
      let current = path[position]
      if position + 1 < pathLength and position mod 3 == color:
        let next = path[position + 1]
        removedNode[removedCount] = current
        removedSuccessor[removedCount] = next
        oldSuccessorWeight[removedCount] = weight[next]
        inc removedCount
        weight[next] += weight[current]
      else:
        path[write] = current
        inc write
    if write == pathLength: return -1
    pathLength = write

  var rank: array[MaxN, int64]
  rank[path[0]] = weight[path[0]]
  while removedCount > 0:
    dec removedCount
    let current = removedNode[removedCount]
    let next = removedSuccessor[removedCount]
    rank[current] = rank[next] - oldSuccessorWeight[removedCount]
  var staged: array[MaxOutput, uint8]
  for index in 0 ..< n:
    let bits = cast[uint64](rank[index])
    for byte in 0 ..< 8:
      staged[8 * index + byte] = uint8((bits shr (8 * byte)) and 255)
  for index in 0 ..< outputBytes: output[index] = staged[index]
  int64(outputBytes)
