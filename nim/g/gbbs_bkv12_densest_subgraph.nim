## Clean-room bounded GBBS BKV12 profile; see package LICENSE.txt.
const MaxN = 16
const MaxM = 64
const MaxInput = 132
const InvalidResult = -1e300

proc gbbs_bkv12_densest_subgraph*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "gbbs_bkv12_densest_subgraph".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return InvalidResult
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM) or int64(length) != 2 + 2*m64: return InvalidResult
  let n = int(n64)
  let m = int(m64)
  var adjacent: array[MaxN * MaxN, bool]
  var degree: array[MaxN, int64]
  var edgeU, edgeV: array[MaxM, int]
  for edge in 0..<m:
    let u64 = input[2 + 2*edge]
    let v64 = input[3 + 2*edge]
    if u64 < 0 or u64 >= v64 or v64 >= n64: return InvalidResult
    let u = int(u64)
    let v = int(v64)
    if adjacent[u * MaxN + v]: return InvalidResult
    adjacent[u * MaxN + v] = true
    adjacent[v * MaxN + u] = true
    inc degree[u]
    inc degree[v]
    edgeU[edge] = u
    edgeV[edge] = v
  var alive: array[MaxN, bool]
  for vertex in 0..<n: alive[vertex] = true
  var remaining = n
  var best = 0.0
  while remaining > 0:
    var total: int64 = 0
    for vertex in 0..<n:
      if alive[vertex]: total += degree[vertex]
    let density = float64(total) / float64(remaining)
    if density > best: best = density
    var removed: array[MaxN, bool]
    var count = 0
    for vertex in 0..<n:
      if alive[vertex] and 1000*degree[vertex]*int64(remaining) <= 1001*total:
        removed[vertex] = true
        inc count
    if count == 0: return InvalidResult
    for vertex in 0..<n:
      if removed[vertex]: alive[vertex] = false
    remaining -= count
    for edge in 0..<m:
      let u = edgeU[edge]
      let v = edgeV[edge]
      if removed[u] and alive[v]: dec degree[v]
      if removed[v] and alive[u]: dec degree[u]
  return best
