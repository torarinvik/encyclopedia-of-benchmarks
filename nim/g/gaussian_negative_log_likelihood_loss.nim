import math

const MaxCount = 256
const MaxInputLength = 1 + 3 * MaxCount
const InvalidResult = -1.0e300

proc gaussian_negative_log_likelihood_loss*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "gaussian_negative_log_likelihood_loss".} =
  if values == nil or length < 4 or length > MaxInputLength: return InvalidResult
  let countValue = values[0]
  if countValue < 1 or countValue > MaxCount: return InvalidResult
  let count = int(countValue)
  if length != csize_t(1 + 3 * count): return InvalidResult
  var total = 0.0
  for i in 0 ..< count:
    let yScaled = values[1 + i]
    let muScaled = values[1 + count + i]
    let varianceNano = values[1 + 2 * count + i]
    if yScaled < -1_000_000 or yScaled > 1_000_000 or muScaled < -1_000_000 or muScaled > 1_000_000 or
        varianceNano < 1 or varianceNano > 1_000_000_000: return InvalidResult
    let y = float64(yScaled) / 1_000_000.0
    let mu = float64(muScaled) / 1_000_000.0
    var variance = float64(varianceNano) / 1_000_000_000.0
    if variance < 1e-6: variance = 1e-6
    let residual = y - mu
    let lossVar = 0.5 * ln(variance)
    let lossExp = 0.5 * ((residual * residual) / variance)
    total += lossVar + lossExp
  total / float64(count)
