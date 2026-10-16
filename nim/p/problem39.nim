const MAX_SQRT = 1415'i64

proc integerSqrt(value: int64): int64 =
  var low = 0'i64
  var high = MAX_SQRT
  while high - low > 1:
    let middle = (low + high) div 2
    if middle * middle <= value: low = middle
    else: high = middle
  low

proc problem39*(limit: int64): int64 {.cdecl, exportc: "problem39".} =
  if limit < 12 or limit > 1000: return -1
  var counts: array[1001, int64]
  var firstOrder: array[1001, int64]
  var nextOrder = 1'i64
  for base in 1'i64 .. limit:
    for perpendicular in base .. limit:
      let squareSum = base * base + perpendicular * perpendicular
      let hypotenuse = integerSqrt(squareSum)
      if hypotenuse * hypotenuse != squareSum: continue
      let perimeter = base + perpendicular + hypotenuse
      if perimeter > limit: continue
      let index = int(perimeter)
      if counts[index] == 0:
        firstOrder[index] = nextOrder
        inc nextOrder
      inc counts[index]
  var bestPerimeter = -1'i64
  var bestCount = 0'i64
  var bestOrder = high(int64)
  for perimeter in 1'i64 .. limit:
    let index = int(perimeter)
    if counts[index] > 0 and (counts[index] > bestCount or
        (counts[index] == bestCount and firstOrder[index] < bestOrder)):
      bestPerimeter = perimeter
      bestCount = counts[index]
      bestOrder = firstOrder[index]
  bestPerimeter
