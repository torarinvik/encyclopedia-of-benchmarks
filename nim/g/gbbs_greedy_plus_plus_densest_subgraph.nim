## Clean-room bounded GBBS GreedyPlusPlus profile; see package LICENSE.txt.
const MaxN = 16
const MaxM = 64
const MaxInput = 132
const InvalidResult = -1e300

proc gbbs_greedy_plus_plus_densest_subgraph*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "gbbs_greedy_plus_plus_densest_subgraph".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return InvalidResult
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 10 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM) or int64(length) != 2 + 2*m64: return InvalidResult
  let n = int(n64)
  let m = int(m64)
  var adjacent: array[MaxN * MaxN, bool]
  var load: array[MaxN, int64]
  for edge in 0..<m:
    let u64 = input[2 + 2*edge]
    let v64 = input[3 + 2*edge]
    if u64 < 0 or u64 >= v64 or v64 >= n64: return InvalidResult
    let u = int(u64)
    let v = int(v64)
    if adjacent[u * MaxN + v]: return InvalidResult
    adjacent[u * MaxN + v] = true
    adjacent[v * MaxN + u] = true
    inc load[u]
    inc load[v]
  var best = 0.0
  for round in 0..<20:
    var degree = load
    var alive: array[MaxN, bool]
    var order, position: array[MaxN, int]
    for vertex in 0..<n: alive[vertex] = true
    var used = 0
    while used < n:
      var level = high(int64)
      for vertex in 0..<n:
        if alive[vertex] and degree[vertex] < level: level = degree[vertex]
      var shell: array[MaxN, int]
      var count = 0
      for vertex in 0..<n:
        if alive[vertex] and degree[vertex] == level:
          shell[count] = vertex
          inc count
      for i in 0..<count:
        alive[shell[i]] = false
        order[used] = shell[i]
        inc used
      for vertex in 0..<n:
        if alive[vertex]:
          var removed = 0'i64
          for i in 0..<count:
            if adjacent[vertex * MaxN + shell[i]]: inc removed
          degree[vertex] = max(degree[vertex] - removed, level)
    for i in 0..<n: position[order[i]] = i
    var densityAbove: array[MaxN, int64]
    for vertex in 0..<n:
      var later = 0'i64
      for other in 0..<n:
        if adjacent[vertex * MaxN + other] and position[other] > position[vertex]: inc later
      densityAbove[position[vertex]] = 2 * later
      load[vertex] += later
    var suffixSum = 0'i64
    for index in countdown(n - 1, 0):
      suffixSum += densityAbove[index]
      best = max(best, float64(suffixSum) / float64(n - index))
  return best
