const MaxPattern = 6
const MaxTarget = 8
const MaxCoord = 16'i64
const MaxPairs = 48

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc point_pattern_translation_voting*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "point_pattern_translation_voting".} =
  if input.isNil or length < csize_t(2) or length > csize_t(31): return -1
  let patternRaw = input[0]
  let targetRaw = input[1]
  if patternRaw < 1 or patternRaw > MaxPattern or targetRaw < 1 or targetRaw > MaxTarget: return -1
  let patternCount = int(patternRaw)
  let targetCount = int(targetRaw)
  if length != csize_t(2 + 2 * (patternCount + targetCount)): return -1
  var px, py: array[MaxPattern, int64]
  var tx, ty: array[MaxTarget, int64]
  var cursor = 2
  for i in 0 ..< patternCount:
    px[i] = input[cursor]; py[i] = input[cursor + 1]; cursor += 2
    if px[i] < -MaxCoord or px[i] > MaxCoord or py[i] < -MaxCoord or py[i] > MaxCoord: return -1
    for j in 0 ..< i:
      if px[i] == px[j] and py[i] == py[j]: return -1
  for i in 0 ..< targetCount:
    tx[i] = input[cursor]; ty[i] = input[cursor + 1]; cursor += 2
    if tx[i] < -MaxCoord or tx[i] > MaxCoord or ty[i] < -MaxCoord or ty[i] > MaxCoord: return -1
    for j in 0 ..< i:
      if tx[i] == tx[j] and ty[i] == ty[j]: return -1
  if output.isNil: return -2

  var dx, dy: array[MaxPairs, int64]
  var pairCount = 0
  for p in 0 ..< patternCount:
    for t in 0 ..< targetCount:
      dx[pairCount] = tx[t] - px[p]; dy[pairCount] = ty[t] - py[p]; inc pairCount
  for i in 1 ..< pairCount:
    let keyX = dx[i]
    let keyY = dy[i]
    var j = i
    while j > 0 and (dx[j - 1] > keyX or (dx[j - 1] == keyX and dy[j - 1] > keyY)):
      dx[j] = dx[j - 1]; dy[j] = dy[j - 1]; dec j
    dx[j] = keyX; dy[j] = keyY
  var bestCount = 0
  var bestX = dx[0]
  var bestY = dy[0]
  var i = 0
  while i < pairCount:
    var ending = i + 1
    while ending < pairCount and dx[ending] == dx[i] and dy[ending] == dy[i]: inc ending
    if ending - i > bestCount:
      bestCount = ending - i; bestX = dx[i]; bestY = dy[i]
    i = ending
  if capacity < csize_t(24): return -2
  var staged: array[24, uint8]
  storeI64Le(addr staged[0], 0, int64(bestCount))
  storeI64Le(addr staged[0], 8, bestX)
  storeI64Le(addr staged[0], 16, bestY)
  for byte in 0 ..< 24: output[byte] = staged[byte]
  24
