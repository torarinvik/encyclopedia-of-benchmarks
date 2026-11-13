const
  MaxCoordinate = 1_000'i64
  MaxRadius = 1_000'i64

proc classify(x1, y1, r1, x2, y2, r2: int64): int64 =
  let dx = x2 - x1
  let dy = y2 - y1
  if dx == 0 and dy == 0:
    if r1 == r2: return 3
    return 0
  let a = -2 * dx
  let b = -2 * dy
  let c = dx * dx + dy * dy + r1 * r1 - r2 * r2
  let discriminant = r1 * r1 * (a * a + b * b) - c * c
  if discriminant < 0: return 0
  if discriminant == 0: return 1
  2

proc circle_circle_intersection_count*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "circle_circle_intersection_count".} =
  if input.isNil or length < csize_t(6) or length > csize_t(7): return -1
  if length != csize_t(6): return -1
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
      r1 < 1 or r1 > MaxRadius or r2 < 1 or r2 > MaxRadius:
    return -1
  classify(x1, y1, r1, x2, y2, r2)
