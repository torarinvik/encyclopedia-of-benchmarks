# Clean-room GBBS fixed-k clique profile; see package LICENSE.txt.
const MaxN = 24
const MaxM = 64
const MaxInput = 130

proc storeI64LE(output: ptr UncheckedArray[uint8], value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[byte] = uint8((bits shr (8 * byte)) and 255)

proc gbbs_k_clique_count*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gbbs_k_clique_count".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM): return -1
  let n = int(n64)
  let m = int(m64)
  if int(length) != 2 + 2 * m: return -1
  var adjacent: array[MaxN, array[MaxN, bool]]
  var degree: array[MaxN, int]
  for edge in 0..<m:
    let u64 = input[2 + 2 * edge]
    let v64 = input[3 + 2 * edge]
    if u64 < 0 or v64 <= u64 or v64 >= n64: return -1
    let u = int(u64)
    let v = int(v64)
    if adjacent[u][v]: return -1
    adjacent[u][v] = true
    adjacent[v][u] = true
    inc degree[u]
    inc degree[v]
  if output.isNil or capacity < csize_t(8): return -2

  var directed: array[MaxN, array[MaxN, bool]]
  for u in 0..<n:
    if degree[u] >= 3:
      for v in (u + 1)..<n:
        if degree[v] >= 3 and adjacent[u][v]: directed[u][v] = true
  var count = 0'i64
  for a in 0..<n:
    for b in (a + 1)..<n:
      if not directed[a][b]: continue
      for c in (b + 1)..<n:
        if not (directed[a][c] and directed[b][c]): continue
        for d in (c + 1)..<n:
          if directed[a][d] and directed[b][d] and directed[c][d]: inc count
  storeI64LE(output, count)
  return 8
