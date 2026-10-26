# Clean-room bounded GBBS k-core profile; see package LICENSE.txt.
const MaxN = 16
const MaxM = 64
const MaxInput = 130

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc gbbs_k_core_decomposition*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gbbs_k_core_decomposition".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM) or
      int64(length) != 2 + 2 * m64: return -1
  let n = int(n64)
  let m = int(m64)
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
  let outputBytes = 8 * n
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var degree: array[MaxN, int]
  var core: array[MaxN, int64]
  var alive: array[MaxN, bool]
  var shell: array[MaxN, bool]
  for u in 0..<n:
    alive[u] = true
    for v in 0..<n:
      if adjacent[u][v]: inc degree[u]
  var remaining = n
  while remaining > 0:
    var k = n
    for u in 0..<n:
      if alive[u] and degree[u] < k: k = degree[u]
    for u in 0..<n:
      shell[u] = alive[u] and degree[u] == k
      if shell[u]:
        alive[u] = false
        core[u] = int64(k)
        dec remaining
    for v in 0..<n:
      if not alive[v]: continue
      var removed = 0
      for u in 0..<n:
        if shell[u] and adjacent[u][v]: inc removed
      if removed > 0: degree[v] = max(degree[v] - removed, k)
  for u in 0..<n: storeI64LE(output, 8 * u, core[u])
  int64(outputBytes)
