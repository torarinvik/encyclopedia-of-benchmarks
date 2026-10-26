const MaxN = 16
const MaxM = 64
const MaxInput = 194

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc gbbs_maximal_matching*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gbbs_maximal_matching".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM) or
      int64(length) != 2 + 3 * m64: return -1
  let m = int(m64)
  let edgeStart = 2 + m
  var rankSeen: array[MaxM, bool]
  var order: array[MaxM, int]
  for edge in 0..<m:
    let rank64 = input[2 + edge]
    if rank64 < 0 or rank64 >= m64: return -1
    let rank = int(rank64)
    if rankSeen[rank]: return -1
    rankSeen[rank] = true
    order[rank] = edge
    let u64 = input[edgeStart + 2 * edge]
    let v64 = input[edgeStart + 2 * edge + 1]
    if u64 < 0 or v64 <= u64 or v64 >= n64: return -1
    for prior in 0..<edge:
      if input[edgeStart + 2 * prior] == u64 and
          input[edgeStart + 2 * prior + 1] == v64: return -1
  let outputBytes = 8 * m
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var matched: array[MaxN, bool]
  var selected: array[MaxM, int64]
  for rank in 0..<m:
    let edge = order[rank]
    let u = int(input[edgeStart + 2 * edge])
    let v = int(input[edgeStart + 2 * edge + 1])
    if not matched[u] and not matched[v]:
      selected[edge] = 1
      matched[u] = true
      matched[v] = true
  for edge in 0..<m:
    storeI64LE(output, 8 * edge, selected[edge])
  int64(outputBytes)
