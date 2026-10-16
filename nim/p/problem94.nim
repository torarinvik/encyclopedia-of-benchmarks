const MaxPerimeter = 1_000_000_000'i64

proc problem94*(maxPerimeter: int64): int64 {.cdecl, exportc: "problem94".} =
  if maxPerimeter < 0 or maxPerimeter > MaxPerimeter: return -1
  var previous = 1'i64
  var value = 2'i64
  var perimeterSum = 0'i64
  var index = 0'i64
  var perimeter = 0'i64
  while perimeter <= maxPerimeter:
    perimeterSum += perimeter
    previous += 2 * value
    value += previous
    if index mod 2 == 0: perimeter = 2 * value + 2
    else: perimeter = 2 * value - 2
    inc index
  perimeterSum
