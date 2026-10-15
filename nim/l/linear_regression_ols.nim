const MaxObservations = 128
const InvalidResult = -1.0e300

proc linear_regression_ols*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "linear_regression_ols".} =
  if values == nil or length < 5 or length > csize_t(257) or length mod 2 == 0: return InvalidResult
  let count = values[0]
  if count < 2 or count > MaxObservations or length != csize_t(1 + 2 * count): return InvalidResult

  var sumX = 0.0
  var sumY = 0.0
  for index in 0 ..< int(count):
    let x = values[1 + 2 * index]
    let y = values[2 + 2 * index]
    if x < -1_000_000 or x > 1_000_000 or y < -1_000_000 or y > 1_000_000: return InvalidResult
    sumX += float64(x)
    sumY += float64(y)
  let meanX = sumX / float64(count)
  let meanY = sumY / float64(count)
  var covariance = 0.0
  var varianceX = 0.0
  var varianceY = 0.0
  for index in 0 ..< int(count):
    let dx = float64(values[1 + 2 * index]) - meanX
    let dy = float64(values[2 + 2 * index]) - meanY
    covariance += dx * dy
    varianceX += dx * dx
    varianceY += dy * dy
  if varianceX <= 1.0e-12 or varianceY <= 1.0e-12: return InvalidResult
  return covariance / varianceX
