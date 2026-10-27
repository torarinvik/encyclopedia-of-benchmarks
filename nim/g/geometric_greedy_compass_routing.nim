const MaxN = 8
const MaxInput = 84
const MaxOutput = 80
const OutputValues = 10

proc put64(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[position+byte] = uint8((bits shr (8*byte)) and 255)

proc angleBetter(da, la, db, lb: int64): bool =
  if (da >= 0) != (db >= 0): return da >= 0
  let left = da*da*lb
  let right = db*db*la
  if da >= 0: return left > right
  left < right

proc angleEqual(da, la, db, lb: int64): bool =
  (da >= 0) == (db >= 0) and da*da*lb == db*db*la

proc geometric_greedy_compass_routing*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "geometric_greedy_compass_routing".} =
  if input.isNil or length < csize_t(12) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let mode = input[1]
  let source64 = input[2]
  let target64 = input[3]
  if n64 < 2 or n64 > int64(MaxN) or mode < 0 or mode > 1 or source64 < 0 or target64 < 0 or source64 >= n64 or target64 >= n64: return -1
  let n = int(n64)
  let source = int(source64)
  let target = int(target64)
  if int64(length) != int64(4+2*n+n*n): return -1
  var x: array[MaxN, int64]
  var y: array[MaxN, int64]
  let adjacency = 4+2*n
  for i in 0 ..< n:
    x[i] = input[4+i]; y[i] = input[4+n+i]
    if x[i] < -8 or x[i] > 8 or y[i] < -8 or y[i] > 8: return -1
    for j in 0 ..< i:
      if x[i] == x[j] and y[i] == y[j]: return -1
  for i in 0 ..< n:
    for j in 0 ..< n:
      let a = input[adjacency+i*n+j]
      let b = input[adjacency+j*n+i]
      if (a != 0 and a != 1) or a != b or (i == j and a != 0): return -1
  if output.isNil or capacity < csize_t(MaxOutput): return -2
  var path: array[MaxN, int]
  var visited: array[MaxN, bool]
  var count = 1
  path[0] = source; visited[source] = true
  var current = source
  while current != target and count < n:
    var best = n
    var bestDot = 0'i64; var bestLen = 1'i64; var bestDistance = 0'i64
    let tx = x[target]-x[current]
    let ty = y[target]-y[current]
    for v in 0 ..< n:
      if input[adjacency+current*n+v] != 1: continue
      var better = best == n
      let dx = x[v]-x[current]
      let dy = y[v]-y[current]
      if mode == 0:
        let rx = x[v]-x[target]
        let ry = y[v]-y[target]
        let distance = rx*rx+ry*ry
        if not better: better = distance < bestDistance or (distance == bestDistance and v < best)
        if better: bestDistance = distance
      else:
        let dot = dx*tx+dy*ty
        let len = dx*dx+dy*dy
        if not better: better = angleBetter(dot,len,bestDot,bestLen) or (angleEqual(dot,len,bestDot,bestLen) and v < best)
        if better: bestDot = dot; bestLen = len
      if better: best = v
    if best == n or visited[best]: break
    path[count] = best; inc count; visited[best] = true; current = best
  var record: array[OutputValues, int64]
  if current == target: record[0] = 1 else: record[0] = 0
  record[1] = int64(count-1)
  for i in 0 ..< MaxN: record[2+i] = -1
  for i in 0 ..< count: record[2+i] = int64(path[i])
  var staged: array[MaxOutput, uint8]
  for i in 0 ..< OutputValues: put64(addr staged[0],8*i,record[i])
  for i in 0 ..< MaxOutput: output[i] = staged[i]
  int64(MaxOutput)
