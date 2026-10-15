import math

const MaxDimension = 128

proc euclidean_distance*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "euclidean_distance".} =
  if values == nil or length < 1: return -1.0e300
  let dimensionValue = values[0]
  if dimensionValue < 0 or dimensionValue > MaxDimension: return -1.0e300
  let dimension = int(dimensionValue)
  if length != csize_t(1 + 2 * dimension): return -1.0e300
  var sumOfSquares = 0.0
  for i in 0 ..< dimension:
    let first = values[csize_t(1 + i)]
    let second = values[csize_t(1 + dimension + i)]
    if (first < -1_000_000 or first > 1_000_000 or
        second < -1_000_000 or second > 1_000_000): return -1.0e300
    let difference = float64(first) - float64(second)
    sumOfSquares += difference * difference
  sqrt(sumOfSquares)
