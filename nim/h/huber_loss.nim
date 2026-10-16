const Scale = 1_000_000'i64
const MaxPairs = 64'i64
const MaxParsedPairs = 65'i64
const MaxSample = 1_000_000_000'i64
const MaxDelta = 1_000_000_000'i64
const MaxInputLength = 133
const InvalidResult = -1.0e300

proc huber_loss*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "huber_loss".} =
  if values == nil or length < 3 or length > MaxInputLength: return InvalidResult
  let deltaValue = values[0]
  let trueCount = values[1]
  let predCount = values[2]
  if deltaValue < 0 or deltaValue > MaxDelta or
      trueCount < 0 or trueCount > MaxParsedPairs or
      predCount < 0 or predCount > MaxParsedPairs: return InvalidResult
  if length != csize_t(3 + trueCount + predCount) or trueCount != predCount or
      predCount == 0 or trueCount > MaxPairs: return InvalidResult

  let count = int(trueCount)
  for index in 0 ..< count * 2:
    if values[3 + index] < -MaxSample or values[3 + index] > MaxSample:
      return InvalidResult
  let delta = float64(deltaValue) / float64(Scale)
  var totalLoss = 0.0
  for index in 0 ..< count:
    let trueValue = float64(values[3 + index]) / float64(Scale)
    let predictedValue = float64(values[3 + count + index]) / float64(Scale)
    let residual = abs(trueValue - predictedValue)
    if residual <= delta:
      totalLoss += 0.5 * (residual * residual)
    else:
      totalLoss += delta * residual - 0.5 * (delta * delta)
  totalLoss / float64(count)
