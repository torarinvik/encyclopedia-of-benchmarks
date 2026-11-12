const
  MaxCoordinate = 100_000'i64
  MaxRadius = 100_000'i64
  InputLength = 6

proc countTangents(x1, y1, r1, x2, y2, r2: int64): int64 =
  let dx = x2 - x1
  let dy = y2 - y1
  let distanceSquared = dx * dx + dy * dy
  let signs = [-1'i64, 1'i64]
  var candidates = 0'i64
  for firstSign in signs:
    for secondSign in signs:
      let difference = secondSign * r2 - firstSign * r1
      if distanceSquared >= difference * difference:
        inc candidates
  if r1 == 0 and r2 == 0: return 1
  if r1 == 0 or r2 == 0:
    let radius = r1 + r2
    if distanceSquared == radius * radius: return 1
    return candidates div 2
  let radiusSum = r1 + r2
  let radiusDifference = r1 - r2
  if distanceSquared == radiusSum * radiusSum or
      distanceSquared == radiusDifference * radiusDifference:
    dec candidates
  candidates

proc common_tangents_two_circles*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "common_tangents_two_circles".} =
  if input.isNil or length != csize_t(InputLength): return -1
  let x1 = input[0]
  let y1 = input[1]
  let r1 = input[2]
  let x2 = input[3]
  let y2 = input[4]
  let r2 = input[5]
  if x1 < -MaxCoordinate or x1 > MaxCoordinate or
      y1 < -MaxCoordinate or y1 > MaxCoordinate or
      x2 < -MaxCoordinate or x2 > MaxCoordinate or
      y2 < -MaxCoordinate or y2 > MaxCoordinate or
      r1 < 0 or r1 > MaxRadius or r2 < 0 or r2 > MaxRadius or
      (x1 == x2 and y1 == y2):
    return -1
  countTangents(x1, y1, r1, x2, y2, r2)
