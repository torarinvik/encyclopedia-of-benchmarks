const MaxN = 16
const MaxM = 64
const MaxInput = 147
const MaxPriority = 99_999_998'i64

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc pannotia_priority_coloring*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "pannotia_priority_coloring".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  let mode64 = input[2]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM) or
      (mode64 != 0 and mode64 != 1) or int64(length) != 3 + n64 + 2 * m64: return -1
  let n = int(n64)
  let m = int(m64)
  let mode = int(mode64)
  var adjacency: array[MaxN, uint64]
  var degree: array[MaxN, int]
  var priority: array[MaxN, int64]
  var color: array[MaxN, int64]
  var active: array[MaxN, bool]
  for v in 0..<n:
    priority[v] = input[3 + v]
    if priority[v] < 0 or priority[v] > MaxPriority: return -1
    for prior in 0..<v:
      if priority[prior] == priority[v]: return -1
    color[v] = -1
    active[v] = true
  for edge in 0..<m:
    let uValue = input[3 + n + 2 * edge]
    let vValue = input[4 + n + 2 * edge]
    if uValue < 0 or vValue <= uValue or vValue >= n64: return -1
    let u = int(uValue)
    let v = int(vValue)
    if (adjacency[u] and (1'u64 shl v)) != 0: return -1
    adjacency[u] = adjacency[u] or (1'u64 shl v)
    adjacency[v] = adjacency[v] or (1'u64 shl u)
    inc degree[u]
    inc degree[v]
  for v in 0..<n:
    if degree[v] == 1: return -1
  let outputBytes = 8 * n
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var currentColor = 1'i64
  while true:
    var chosen: array[MaxN, bool]
    var chosenCount = 0
    for v in 0..<n:
      if not active[v]: continue
      var maximum = -1'i64
      var minimum = 99_999_999'i64
      for u in 0..<n:
        if active[u] and (adjacency[v] and (1'u64 shl u)) != 0:
          if priority[u] > maximum: maximum = priority[u]
          if priority[u] < minimum: minimum = priority[u]
      if priority[v] > maximum:
        color[v] = currentColor
        chosen[v] = true
      if mode == 1 and priority[v] < minimum:
        color[v] = currentColor + 1
        chosen[v] = true
      if chosen[v]: inc chosenCount
    if chosenCount == 0: return -1
    for v in 0..<n:
      if chosen[v]: active[v] = false
    var remaining = false
    for v in 0..<n: remaining = remaining or active[v]
    if not remaining: break
    if mode == 1: currentColor += 2 else: inc currentColor
  for v in 0..<n: storeI64LE(output, 8 * v, color[v])
  int64(outputBytes)
