const MaxN = 8
const MaxInputLength = 59

proc reverse_cuthill_mckee*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "reverse_cuthill_mckee".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > MaxN: return -1
  let n = int(n64)
  if m64 < 0 or m64 > int64(n * (n - 1) div 2): return -1
  let m = int(m64)
  if length != csize_t(2 + 2 * m): return -1

  var adjacency: array[MaxN, array[MaxN, bool]]
  for edge in 0..<m:
    let u64 = input[2 + 2 * edge]
    let v64 = input[3 + 2 * edge]
    if u64 < 0 or u64 >= n64 or v64 < 0 or v64 >= n64 or u64 == v64:
      return -1
    let u = int(u64)
    let v = int(v64)
    if adjacency[u][v]: return -1
    adjacency[u][v] = true
    adjacency[v][u] = true

  var degree: array[MaxN, int]
  for u in 0..<n:
    for v in 0..<n:
      if adjacency[u][v]: inc degree[u]

  var visited: array[MaxN, bool]
  var queue: array[MaxN, int]
  var cmOrder: array[MaxN, int]
  var orderCount = 0
  while orderCount < n:
    var root = -1
    for v in 0..<n:
      if not visited[v]:
        if root < 0:
          root = v
        elif degree[v] < degree[root] or (degree[v] == degree[root] and v < root):
          root = v
    if root < 0: return -1
    var head = 0
    var tail = 1
    queue[0] = root
    visited[root] = true
    while head < tail:
      let current = queue[head]
      inc head
      cmOrder[orderCount] = current
      inc orderCount

      var neighbors: array[MaxN, int]
      var neighborCount = 0
      for v in 0..<n:
        if adjacency[current][v] and not visited[v]:
          neighbors[neighborCount] = v
          inc neighborCount
      for i in 1..<neighborCount:
        let key = neighbors[i]
        var j = i
        while j > 0 and (degree[neighbors[j - 1]] > degree[key] or
            (degree[neighbors[j - 1]] == degree[key] and neighbors[j - 1] > key)):
          neighbors[j] = neighbors[j - 1]
          dec j
        neighbors[j] = key
      for i in 0..<neighborCount:
        let next = neighbors[i]
        if not visited[next]:
          visited[next] = true
          queue[tail] = next
          inc tail

  var rank: array[MaxN, int]
  for i in 0..<n:
    rank[cmOrder[n - 1 - i]] = i
  var bandwidth = 0
  for u in 0..<n:
    for v in u + 1..<n:
      if adjacency[u][v]:
        let distance = abs(rank[u] - rank[v])
        if distance > bandwidth: bandwidth = distance
  var rankWord = 0'i64
  for i in 0..<n:
    rankWord = rankWord or (int64(cmOrder[n - 1 - i]) shl (3 * i))
  (int64(bandwidth) shl 24) or rankWord
