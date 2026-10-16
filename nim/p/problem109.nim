proc problem109*(limit: int64): int64 {.cdecl, exportc: "problem109".} =
  var values: array[63, int64]
  var doubles: array[21, int64]
  var valueCount = 0
  var doubleCount = 0
  for score in 1 .. 20: values[valueCount] = score.int64; inc valueCount
  values[valueCount] = 25; inc valueCount
  for score in 1 .. 20:
    doubles[doubleCount] = 2 * score
    values[valueCount] = 2 * score
    inc doubleCount; inc valueCount
  doubles[doubleCount] = 50; values[valueCount] = 50; inc doubleCount; inc valueCount
  for score in 1 .. 20: values[valueCount] = 3 * score.int64; inc valueCount
  values[valueCount] = 0; inc valueCount
  var count = 0'i64
  for d in 0 ..< doubleCount:
    for first in 0 ..< valueCount:
      for second in first ..< valueCount:
        if doubles[d] + values[first] + values[second] < limit: inc count
  count
