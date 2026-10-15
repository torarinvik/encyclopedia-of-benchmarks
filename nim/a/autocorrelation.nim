const MaxLength = 64
const InvalidResult = -1.0e300

proc autocorrelation*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "autocorrelation".} =
  if values == nil or length < 4 or length > csize_t(MaxLength + 2): return InvalidResult
  let countValue = values[0]
  let lagValue = values[1]
  if countValue < 2 or countValue > MaxLength or length != csize_t(countValue + 2) or lagValue < 0 or lagValue >= countValue:
    return InvalidResult
  let count = int(countValue)
  let lag = int(lagValue)
  var sum = 0.0
  for index in 0 ..< count:
    let value = values[index + 2]
    if value < -1000 or value > 1000: return InvalidResult
    sum += float64(value)
  let mean = sum / float64(count)
  var varianceSum = 0.0
  for index in 0 ..< count:
    let difference = float64(values[index + 2]) - mean
    varianceSum += difference * difference
  if varianceSum == 0.0: return InvalidResult
  let variance = varianceSum / float64(count)
  var covarianceSum = 0.0
  for index in lag ..< count:
    let current = float64(values[index + 2]) - mean
    let delayed = float64(values[index - lag + 2]) - mean
    covarianceSum += current * delayed
  return (covarianceSum / float64(count)) / variance
