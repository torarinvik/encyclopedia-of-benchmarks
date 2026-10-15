import math

const MaxLength = 64
const InvalidResult = -1.0e300

proc quadratic_mean*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "quadratic_mean".} =
  if values == nil or length == 0 or length > csize_t(MaxLength): return InvalidResult
  var squareSum = 0.0
  for index in 0 ..< int(length):
    let value = values[index]
    if value < -1000 or value > 1000: return InvalidResult
    let converted = float64(value)
    squareSum += converted * converted
  return sqrt(squareSum / float64(length))
