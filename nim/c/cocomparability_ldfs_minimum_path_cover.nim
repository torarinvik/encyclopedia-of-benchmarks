const MaxVertices = 8
const MaxParseableLength = 18

proc cocomparability_ldfs_minimum_path_cover*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "cocomparability_ldfs_minimum_path_cover".} =
  if input == nil or length < 1 or length > csize_t(MaxParseableLength): return -1
  let n64 = input[0]
  if n64 < 1 or n64 > MaxVertices.int64: return -1
  let n = int(n64)
  if int(length) != 1 + 2*n: return -1
  let full = (1'u16 shl n) - 1'u16
  var adjacency: array[MaxVertices, uint16]
  var order, rank, position: array[MaxVertices, int]
  var seenOrder: array[MaxVertices, bool]
  for v in 0 ..< n:
    let row = input[1 + v]
    if row < 0 or row > full.int64 or (row and (1'i64 shl v)) != 0: return -1
    adjacency[v] = row.uint16
  for u in 0 ..< n:
    for v in 0 ..< n:
      if ((adjacency[u] shr v) and 1'u16) != ((adjacency[v] shr u) and 1'u16): return -1
  for i in 0 ..< n:
    let value = input[1 + n + i]
    if value < 0 or value >= n64 or seenOrder[value.int]: return -1
    order[i] = value.int
    rank[value.int] = i
    seenOrder[value.int] = true
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      for k in j + 1 ..< n:
        let a = order[i]
        let b = order[j]
        let c = order[k]
        if ((adjacency[a] shr c) and 1'u16) != 0'u16 and
           ((adjacency[a] shr b) and 1'u16) == 0'u16 and
           ((adjacency[b] shr c) and 1'u16) == 0'u16: return -1
  var reached: uint16 = 1
  var queue: array[MaxVertices, int]
  var head = 0
  var tail = 1
  queue[0] = 0
  while head < tail:
    let u = queue[head]
    inc head
    for v in 0 ..< n:
      let bit = 1'u16 shl v
      if (adjacency[u] and bit) != 0'u16 and (reached and bit) == 0'u16:
        reached = reached or bit
        queue[tail] = v
        inc tail
  if reached != full: return -1

  var labels: array[MaxVertices, uint64]
  var visited: array[MaxVertices, bool]
  var ldfs: array[MaxVertices, int]
  for step in 1 .. n:
    var chosen = -1
    for v in 0 ..< n:
      if not visited[v] and (chosen < 0 or labels[v] > labels[chosen] or
          (labels[v] == labels[chosen] and rank[v] > rank[chosen])):
        chosen = v
    ldfs[step - 1] = chosen
    visited[chosen] = true
    for v in 0 ..< n:
      if not visited[v] and (adjacency[chosen] and (1'u16 shl v)) != 0'u16:
        labels[v] = (labels[v] shr 4) or (step.uint64 shl 60)
  for i in 0 ..< n: position[ldfs[i]] = i

  for v in 0 ..< n: visited[v] = false
  var paths = 0
  while true:
    var current = -1
    for v in 0 ..< n:
      if not visited[v] and (current < 0 or position[v] > position[current]): current = v
    if current < 0: break
    inc paths
    visited[current] = true
    while true:
      var next = -1
      for v in 0 ..< n:
        if not visited[v] and (adjacency[current] and (1'u16 shl v)) != 0'u16 and
            (next < 0 or position[v] > position[next]): next = v
      if next < 0: break
      visited[next] = true
      current = next
  paths.int64
