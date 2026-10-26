# Clean-room bounded GBBS Charikar profile; see package LICENSE.txt.
const MaxN = 16
const MaxM = 64
const InvalidResult = -1e300

proc gbbs_charikar_densest_subgraph*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "gbbs_charikar_densest_subgraph".} =
  if input.isNil or length < csize_t(2) or length > csize_t(130): return InvalidResult
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM) or int64(length) != 2 + 2 * m64: return InvalidResult
  let n = int(n64)
  let m = int(m64)
  var adjacent: array[MaxN * MaxN, bool]
  var degree: array[MaxN, int]
  for edge in 0 ..< m:
    let u64 = input[2 + 2 * edge]
    let v64 = input[3 + 2 * edge]
    if u64 < 0 or u64 >= v64 or v64 >= n64: return InvalidResult
    let u = int(u64)
    let v = int(v64)
    if adjacent[u * MaxN + v]: return InvalidResult
    adjacent[u * MaxN + v] = true
    adjacent[v * MaxN + u] = true
    inc degree[u]
    inc degree[v]
  var alive: array[MaxN, bool]
  var order, position: array[MaxN, int]
  for v in 0 ..< n: alive[v] = true
  var used = 0
  while used < n:
    var level = MaxM
    for v in 0 ..< n:
      if alive[v] and degree[v] < level: level = degree[v]
    while true:
      var shell: array[MaxN, int]
      var count = 0
      for v in 0 ..< n:
        if alive[v] and degree[v] == level:
          shell[count] = v
          inc count
      if count == 0: break
      for i in 0 ..< count:
        alive[shell[i]] = false
        order[used] = shell[i]
        inc used
      for v in 0 ..< n:
        if alive[v]:
          var removed = 0
          for i in 0 ..< count:
            if adjacent[v * MaxN + shell[i]]: inc removed
          degree[v] = max(degree[v] - removed, level)
  for i in 0 ..< n: position[order[i]] = i
  var best = 0.0
  for start in 0 ..< n:
    var edges = 0
    for u in 0 ..< n:
      if position[u] >= start:
        for v in u + 1 ..< n:
          if position[v] >= start and adjacent[u * MaxN + v]: inc edges
    let score = 2.0 * float64(edges) / float64(n - start)
    if score > best: best = score
  best
