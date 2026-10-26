## Clean-room bounded GBBS Barenboim-Elkin degeneracy-order profile.
const MaxN = 20
const MaxM = 190
const MaxInput = 382

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc gbbs_barenboim_elkin_degeneracy_order*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gbbs_barenboim_elkin_degeneracy_order".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM): return -1
  let n = int(n64)
  let m = int(m64)
  if int(length) != 2 + 2 * m: return -1
  var adjacent: array[MaxN, array[MaxN, bool]]
  var initialDegree: array[MaxN, int]
  for edge in 0..<m:
    let u64 = input[2 + 2*edge]
    let v64 = input[3 + 2*edge]
    if u64 < 0 or u64 >= v64 or v64 >= n64: return -1
    let u = int(u64)
    let v = int(v64)
    if adjacent[u][v]: return -1
    adjacent[u][v] = true
    adjacent[v][u] = true
    inc initialDegree[u]
    inc initialDegree[v]
  if output.isNil or capacity < csize_t(8*n): return -2
  var degree = initialDegree
  var alive: array[MaxN, bool]
  for v in 0..<n: alive[v] = true
  var remaining = n
  var bestNum = 0
  var bestDen = 1
  while remaining > 0:
    var total = 0
    for v in 0..<n:
      if alive[v]: total += degree[v]
    if total * bestDen > bestNum * remaining:
      bestNum = total
      bestDen = remaining
    var removed: array[MaxN, bool]
    var count = 0
    for v in 0..<n:
      if alive[v] and 10 * degree[v] * remaining <= 11 * total:
        removed[v] = true
        inc count
    if count == 0: return -1
    for v in 0..<n:
      if removed[v]: alive[v] = false
    remaining -= count
    for v in 0..<n:
      if alive[v]:
        var decrement = 0
        for u in 0..<n:
          if removed[u] and adjacent[v][u]: inc decrement
        degree[v] -= decrement
  var cutoff = (bestNum + 10 * bestDen - 1) div (10 * bestDen)
  if cutoff < 1: cutoff = 1
  degree = initialDegree
  for v in 0..<n: alive[v] = true
  var order: array[MaxN, int]
  var used = 0
  while used < n:
    var shell: array[MaxN, int]
    var count = 0
    for v in 0..<n:
      if alive[v] and degree[v] < cutoff:
        shell[count] = v
        inc count
    if count == 0:
      for v in 0..<n:
        if alive[v]:
          shell[count] = v
          inc count
          break
    for i in 0..<count:
      alive[shell[i]] = false
      order[used] = shell[i]
      inc used
    for v in 0..<n:
      if alive[v]:
        var decrement = 0
        for i in 0..<count:
          if adjacent[v][shell[i]]: inc decrement
        degree[v] -= decrement
  var rank: array[MaxN, int64]
  for i in 0..<n: rank[order[i]] = int64(i)
  for v in 0..<n: storeI64LE(output, 8*v, rank[v])
  return int64(8*n)
