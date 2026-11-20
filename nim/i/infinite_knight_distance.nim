const MaxCoordinate = 1_000_000_000'i64

proc infinite_knight_distance*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "infinite_knight_distance".} =
  if input.isNil or length != csize_t(2): return -1
  let dx = input[0]
  let dy = input[1]
  if dx < -MaxCoordinate or dx > MaxCoordinate or dy < -MaxCoordinate or dy > MaxCoordinate:
    return -1
  let absX = if dx < 0: -dx else: dx
  let absY = if dy < 0: -dy else: dy
  let large = max(absX, absY)
  let small = min(absX, absY)
  if large == 1 and small == 0: return 3
  if large == 2 and small == 2: return 4
  var distance = (large + 1) div 2
  let diagonalBound = (large + small + 2) div 3
  if diagonalBound > distance: distance = diagonalBound
  if (large + small - distance) mod 2 != 0: inc distance
  distance
