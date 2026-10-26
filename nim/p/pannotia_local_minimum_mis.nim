const MaxN = 16
const MaxM = 64
const MaxInput = 146
const MaxPriority = 99_999_998'i64

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc pannotia_local_minimum_mis*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "pannotia_local_minimum_mis".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM) or
      int64(length) != 2 + n64 + 2 * m64: return -1
  let n = int(n64)
  let m = int(m64)
  var adjacency: array[MaxN, uint64]
  var priority: array[MaxN, int64]
  for v in 0..<n:
    priority[v] = input[2 + v]
    if priority[v] < 0 or priority[v] > MaxPriority: return -1
    for prior in 0..<v:
      if priority[prior] == priority[v]: return -1
  for edge in 0..<m:
    let u64 = input[2 + n + 2 * edge]
    let v64 = input[3 + n + 2 * edge]
    if u64 < 0 or v64 <= u64 or v64 >= n64: return -1
    let u = int(u64)
    let v = int(v64)
    if (adjacency[u] and (1'u64 shl v)) != 0: return -1
    adjacency[u] = adjacency[u] or (1'u64 shl v)
    adjacency[v] = adjacency[v] or (1'u64 shl u)
  let outputBytes = 8 * n
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var active: array[MaxN, bool]
  var selected: array[MaxN, bool]
  for v in 0..<n: active[v] = true
  while true:
    var chosen: array[MaxN, bool]
    var chosenCount = 0
    for v in 0..<n:
      if not active[v]: continue
      var localMinimum = true
      for u in 0..<n:
        if active[u] and (adjacency[v] and (1'u64 shl u)) != 0 and priority[u] < priority[v]:
          localMinimum = false
      if localMinimum:
        chosen[v] = true
        inc chosenCount
    if chosenCount == 0: return -1
    for v in 0..<n:
      if chosen[v]:
        selected[v] = true
        active[v] = false
    for v in 0..<n:
      if chosen[v]:
        for u in 0..<n:
          if active[u] and (adjacency[v] and (1'u64 shl u)) != 0: active[u] = false
    var remaining = false
    for v in 0..<n: remaining = remaining or active[v]
    if not remaining: break
  for v in 0..<n: storeI64LE(output, 8 * v, if selected[v]: 2 else: 0)
  int64(outputBytes)
