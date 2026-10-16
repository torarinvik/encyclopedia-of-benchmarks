import std/math

const MaxObservations = 128
const MaxAbsValue = 1_000_000'i64
const InvalidResult = -1.0e300

proc pearson_correlation*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "pearson_correlation".} =
  if values == nil or length < 5 or length > csize_t(257): return InvalidResult
  let count = values[0]
  if count < 2 or count > MaxObservations or length != csize_t(1 + 2 * count): return InvalidResult

  var sumX = 0.0
  var sumY = 0.0
  for i in 0 ..< int(count):
    let x = values[1 + i]
    let y = values[1 + int(count) + i]
    if x < -MaxAbsValue or x > MaxAbsValue or y < -MaxAbsValue or y > MaxAbsValue: return InvalidResult
    sumX += float64(x)
    sumY += float64(y)
  let meanX = sumX / float64(count)
  let meanY = sumY / float64(count)
  var covariance = 0.0
  var varianceX = 0.0
  var varianceY = 0.0
  for i in 0 ..< int(count):
    let dx = float64(values[1 + i]) - meanX
    let dy = float64(values[1 + int(count) + i]) - meanY
    covariance += dx * dy
    varianceX += dx * dx
    varianceY += dy * dy
  if varianceX == 0.0 or varianceY == 0.0: return InvalidResult
  return covariance / sqrt(varianceX * varianceY)
