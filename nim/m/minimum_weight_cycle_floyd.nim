const MaxN = 9
const MaxCells = 81
const MaxInputLength = 111
const Inf = 1'i64 shl 60

proc storeI64Le(output: ptr UncheckedArray[uint8], value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[byte] = uint8((bits shr (8 * byte)) and 255)

proc minimum_weight_cycle_floyd*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "minimum_weight_cycle_floyd".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 3 or nValue > int64(MaxN) or mValue < 0
      or mValue > nValue * (nValue - 1) div 2: return -1
  let n = int(nValue)
  let m = int(mValue)
  if length != csize_t(2 + 3 * m): return -1

  var edge: array[MaxCells, int64]
  var dist: array[MaxCells, int64]
  for i in 0 ..< n:
    for j in 0 ..< n:
      edge[i * MaxN + j] = if i == j: 0'i64 else: Inf
  for e in 0 ..< m:
    let offset = 2 + 3 * e
    let uValue = input[offset]
    let vValue = input[offset + 1]
    let weight = input[offset + 2]
    if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue
        or uValue == vValue or weight < 1 or weight > 1000: return -1
    let u = int(uValue)
    let v = int(vValue)
    if edge[u * MaxN + v] != Inf: return -1
    edge[u * MaxN + v] = weight
    edge[v * MaxN + u] = weight
  if output.isNil or capacity < 8: return -2
  for i in 0 ..< n:
    for j in 0 ..< n:
      dist[i * MaxN + j] = edge[i * MaxN + j]

  var best = Inf
  for k in 0 ..< n:
    for i in 0 ..< k:
      if edge[i * MaxN + k] == Inf: continue
      for j in (i + 1) ..< k:
        if edge[k * MaxN + j] == Inf or dist[i * MaxN + j] == Inf: continue
        let candidate = edge[i * MaxN + k] + edge[k * MaxN + j] + dist[i * MaxN + j]
        if candidate < best: best = candidate
    for i in 0 ..< n:
      if dist[i * MaxN + k] == Inf: continue
      for j in 0 ..< n:
        if dist[k * MaxN + j] == Inf: continue
        let candidate = dist[i * MaxN + k] + dist[k * MaxN + j]
        if candidate < dist[i * MaxN + j]: dist[i * MaxN + j] = candidate
  storeI64Le(output, if best == Inf: -1'i64 else: best)
  8
