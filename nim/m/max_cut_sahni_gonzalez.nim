const MaxN = 16
const MaxM = 120
const MaxInput = 362

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc max_cut_sahni_gonzalez*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "max_cut_sahni_gonzalez".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM) or
      int64(length) != 2 + 3 * m64: return -1
  let n = int(n64)
  let m = int(m64)
  var weights: array[MaxN, array[MaxN, int64]]
  var seen: array[MaxN, array[MaxN, bool]]
  for edge in 0..<m:
    let u64 = input[2 + 3 * edge]
    let v64 = input[3 + 3 * edge]
    let weight = input[4 + 3 * edge]
    if u64 < 0 or v64 <= u64 or v64 >= n64 or weight < 0 or weight > 10000: return -1
    let u = int(u64)
    let v = int(v64)
    if seen[u][v]: return -1
    seen[u][v] = true
    weights[u][v] = weight
    weights[v][u] = weight
  let outputBytes = 8 * (n + 1)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var side: array[MaxN, int64]
  for vertex in 0..<n:
    var putZero = 0'i64
    var putOne = 0'i64
    for prior in 0..<vertex:
      if side[prior] == 1: putZero += weights[prior][vertex]
      else: putOne += weights[prior][vertex]
    side[vertex] = if putOne > putZero: 1 else: 0
  var cut = 0'i64
  for u in 0..<n:
    for v in (u + 1)..<n:
      if side[u] != side[v]: cut += weights[u][v]
  storeI64LE(output, 0, cut)
  for vertex in 0..<n:
    storeI64LE(output, 8 * (vertex + 1), side[vertex])
  int64(outputBytes)
