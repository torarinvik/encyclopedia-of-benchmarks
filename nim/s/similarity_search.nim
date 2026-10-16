import math

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset + b] = uint8((bits shr (8 * b)) and 0xFF'u64)
proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset + b] = uint8((bits shr (8 * b)) and 0xFF'u64)

proc similarity_search*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "similarity_search".} =
  if input.isNil or length < 3 or length > 643: return -1
  let rv = input[0]; let qv = input[1]; let fv = input[2]
  if rv < 1 or rv > 32 or qv < 1 or qv > 8 or fv < 1 or fv > 16: return -1
  let rows = int(rv); let queries = int(qv); let features = int(fv)
  if int(length) != 3 + (rows + queries) * features: return -1
  for i in 0 ..< (rows + queries) * features:
    if input[3 + i] < -1_000_000 or input[3 + i] > 1_000_000: return -1
  let record = 16 + 8 * features; let needed = queries * record
  if output.isNil or outputCapacity < csize_t(needed): return -2
  for query in 0 ..< queries:
    var best = 0
    var sum = 0.0
    for f in 0 ..< features:
      let delta = float64(input[3 + f]) / 1_000_000.0 - float64(input[3 + rows * features + query * features + f]) / 1_000_000.0
      sum += delta * delta
    var bestDistance = sqrt(sum)
    for row in 1 ..< rows:
      sum = 0.0
      for f in 0 ..< features:
        let delta = float64(input[3 + row * features + f]) / 1_000_000.0 - float64(input[3 + rows * features + query * features + f]) / 1_000_000.0
        sum += delta * delta
      let distance = sqrt(sum)
      if distance < bestDistance: best = row; bestDistance = distance
    let base = query * record
    putI64Le(output, base, int64(best))
    putF64Le(output, base + 8, bestDistance)
    for f in 0 ..< features: putI64Le(output, base + 16 + 8 * f, input[3 + best * features + f])
  int64(needed)
