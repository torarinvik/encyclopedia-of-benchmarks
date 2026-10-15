import math

const MaxLength = 256
const InvalidResult = -1.0e300

proc mean_absolute_deviation*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "mean_absolute_deviation".} =
  if values == nil or length < 2 or length > csize_t(MaxLength + 1): return InvalidResult
  let countValue = values[0]
  if countValue < 1 or countValue > MaxLength or length != csize_t(countValue + 1): return InvalidResult
  let count = int(countValue)
  var sum = 0.0
  for index in 0 ..< count:
    let value = values[index + 1]
    if value < -1_000_000 or value > 1_000_000: return InvalidResult
    sum += float64(value)
  let mean = sum / float64(count)
  var absoluteSum = 0.0
  for index in 0 ..< count:
    absoluteSum += abs(float64(values[index + 1]) - mean)
  return absoluteSum / float64(count)
