const MaxDimension = 15
const MaxStates = 1 shl MaxDimension

proc bitCount(value: int): int =
  var remaining = value
  while remaining != 0:
    result += remaining and 1
    remaining = remaining shr 1

proc problem345*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "problem345".} =
  if input == nil or length < 2 or length > (MaxDimension * MaxDimension + 1).csize_t: return -1
  let dimension = input[0]
  if dimension < 1 or dimension > MaxDimension.int64 or length.int != (dimension * dimension).int + 1: return -1
  for index in 1 ..< length.int:
    if input[index] < 0 or input[index] > 1000: return -1

  var best: array[MaxStates, int64]
  for mask in 0 ..< MaxStates: best[mask] = -1
  best[0] = 0
  let stateCount = 1 shl int(dimension)
  for mask in 0 ..< stateCount:
    if best[mask] < 0: continue
    let row = bitCount(mask)
    if row >= dimension.int: continue
    for column in 0 ..< dimension.int:
      let bit = 1 shl column
      if (mask and bit) != 0: continue
      let next = mask or bit
      let candidate = best[mask] + input[1 + row * dimension.int + column]
      if candidate > best[next]: best[next] = candidate
  best[stateCount - 1]
