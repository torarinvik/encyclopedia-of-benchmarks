# Clean-room bounded GBBS Goodrich-Pszona degeneracy-order profile.
const MaxN = 20
const MaxM = 190
const MaxInput = 382

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc gbbs_goodrich_pszona_degeneracy_order*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gbbs_goodrich_pszona_degeneracy_order".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM): return -1
  let n = int(n64)
  let m = int(m64)
  if int(length) != 2 + 2 * m: return -1
  var adjacent: array[MaxN, array[MaxN, bool]]
  for edge in 0..<m:
    let u64 = input[2 + 2 * edge]
    let v64 = input[3 + 2 * edge]
    if u64 < 0 or v64 <= u64 or v64 >= n64: return -1
    let u = int(u64)
    let v = int(v64)
    if adjacent[u][v]: return -1
    adjacent[u][v] = true
    adjacent[v][u] = true
  if output.isNil or capacity < csize_t(8 * n): return -2
  var degree: array[MaxN, int]
  var remaining: array[MaxN, bool]
  var rank: array[MaxN, int64]
  for vertex in 0..<n:
    remaining[vertex] = true
    for neighbor in 0..<n:
      if adjacent[vertex][neighbor]: inc degree[vertex]
  for position in 0..<n:
    var chosen = n
    for vertex in 0..<n:
      if remaining[vertex] and (chosen == n or degree[vertex] < degree[chosen]):
        chosen = vertex
    rank[chosen] = int64(position)
    remaining[chosen] = false
    for neighbor in 0..<n:
      if remaining[neighbor] and adjacent[chosen][neighbor]: dec degree[neighbor]
  for vertex in 0..<n:
    storeI64LE(output, 8 * vertex, rank[vertex])
  return int64(8 * n)
