const
  MaxVertices = 10
  MaxEdges = 45
  MaxParseableLength = 93

proc dmpcAugment(left, n: int, used: uint16, adjacency: array[MaxVertices, uint16],
                 seen: var array[MaxVertices, bool], matchRight: var array[MaxVertices, int]): bool =
  for right in 0 ..< n:
    let bit = uint16(1 shl right)
    if (adjacency[left] and bit) == 0 or (used and bit) != 0 or seen[right]: continue
    seen[right] = true
    let mate = matchRight[right]
    if mate < 0 or dmpcAugment(mate, n, used, adjacency, seen, matchRight):
      matchRight[right] = left
      return true
  false

proc dmpcMaximum(n, first: int, used: uint16,
                 adjacency: array[MaxVertices, uint16]): int =
  var matchRight: array[MaxVertices, int]
  for right in 0 ..< MaxVertices: matchRight[right] = -1
  for left in first ..< n:
    var seen: array[MaxVertices, bool]
    if dmpcAugment(left, n, used, adjacency, seen, matchRight): inc result

proc dag_minimum_path_cover*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "dag_minimum_path_cover".} =
  if input == nil or length < 2 or length > csize_t(MaxParseableLength): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > MaxVertices.int64 or m64 < 0 or m64 > MaxEdges.int64: return -1
  let n = int(n64)
  let m = int(m64)
  if int(length) != 2 + 2*m: return -1

  var adjacency: array[MaxVertices, uint16]
  var indegree: array[MaxVertices, int]
  for edge in 0 ..< m:
    let u64 = input[2 + 2*edge]
    let v64 = input[3 + 2*edge]
    if u64 < 0 or u64 >= n64 or v64 < 0 or v64 >= n64 or u64 == v64: return -1
    let u = int(u64)
    let v = int(v64)
    let bit = uint16(1 shl v)
    if (adjacency[u] and bit) != 0: return -1
    adjacency[u] = adjacency[u] or bit
    inc indegree[v]

  var queue: array[MaxVertices, int]
  var head = 0
  var tail = 0
  for vertex in 0 ..< n:
    if indegree[vertex] == 0:
      queue[tail] = vertex
      inc tail
  var removed = 0
  while head < tail:
    let u = queue[head]
    inc head
    inc removed
    for v in 0 ..< n:
      if (adjacency[u] and uint16(1 shl v)) != 0:
        dec indegree[v]
        if indegree[v] == 0:
          queue[tail] = v
          inc tail
  if removed != n: return -1

  let maximum = dmpcMaximum(n, 0, 0, adjacency)
  var successor: array[MaxVertices, int]
  for vertex in 0 ..< n: successor[vertex] = n
  var used: uint16 = 0
  var fixed = 0
  for left in 0 ..< n:
    var chosen = false
    for right in 0 .. n:
      let matched = right < n
      if matched:
        let bit = uint16(1 shl right)
        if (adjacency[left] and bit) == 0 or (used and bit) != 0: continue
      let nextUsed = if matched: used or uint16(1 shl right) else: used
      if fixed + (if matched: 1 else: 0) + dmpcMaximum(n, left + 1, nextUsed, adjacency) == maximum:
        successor[left] = right
        used = nextUsed
        if matched: inc fixed
        chosen = true
        break
    if not chosen: return -1

  var packed = int64(n - maximum) shl 40
  for vertex in 0 ..< n: packed = packed or (int64(successor[vertex]) shl (4*vertex))
  packed
