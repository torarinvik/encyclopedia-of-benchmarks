const MaxPattern = 6
const MaxTarget = 8
const MaxCoord = 16'i64

proc pointLess(ax, ay, bx, by: int64): bool = ax < bx or (ax == bx and ay < by)

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc point_pattern_translation_lex_scan*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "point_pattern_translation_lex_scan".} =
  if input.isNil or length < csize_t(2) or length > csize_t(31): return -1
  let patternRaw = input[0]
  let targetRaw = input[1]
  if patternRaw < 1 or patternRaw > MaxPattern or targetRaw < 1 or targetRaw > MaxTarget or patternRaw > targetRaw: return -1
  let patternCount = int(patternRaw)
  let targetCount = int(targetRaw)
  if length != csize_t(2 + 2 * (patternCount + targetCount)): return -1
  var px, py: array[MaxPattern, int64]
  var tx, ty: array[MaxTarget, int64]
  var cursor = 2
  for i in 0 ..< patternCount:
    px[i] = input[cursor]; py[i] = input[cursor + 1]; cursor += 2
    if px[i] < -MaxCoord or px[i] > MaxCoord or py[i] < -MaxCoord or py[i] > MaxCoord: return -1
    if i > 0 and not pointLess(px[i - 1], py[i - 1], px[i], py[i]): return -1
  for i in 0 ..< targetCount:
    tx[i] = input[cursor]; ty[i] = input[cursor + 1]; cursor += 2
    if tx[i] < -MaxCoord or tx[i] > MaxCoord or ty[i] < -MaxCoord or ty[i] > MaxCoord: return -1
    if i > 0 and not pointLess(tx[i - 1], ty[i - 1], tx[i], ty[i]): return -1
  if output.isNil or capacity < csize_t(24): return -2

  var found = 0'i64
  var bestX = 0'i64
  var bestY = 0'i64
  for anchor in 0 ..< targetCount:
    let dx = tx[anchor] - px[0]
    let dy = ty[anchor] - py[0]
    var targetIndex = anchor + 1
    var matches = true
    for patternIndex in 1 ..< patternCount:
      let wantedX = px[patternIndex] + dx
      let wantedY = py[patternIndex] + dy
      while targetIndex < targetCount and pointLess(tx[targetIndex], ty[targetIndex], wantedX, wantedY): inc targetIndex
      if targetIndex >= targetCount or tx[targetIndex] != wantedX or ty[targetIndex] != wantedY:
        matches = false
        break
      inc targetIndex
    if matches:
      found = 1; bestX = dx; bestY = dy
      break
  var staged: array[24, uint8]
  storeI64Le(addr staged[0], 0, found)
  storeI64Le(addr staged[0], 8, bestX)
  storeI64Le(addr staged[0], 16, bestY)
  for byte in 0 ..< 24: output[byte] = staged[byte]
  24
