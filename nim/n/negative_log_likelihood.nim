## Binary negative log-likelihood with source-ordered accumulation.
import math

const MaxCount = 64
const Scale = 1_000_000.0

proc negative_log_likelihood*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "negative_log_likelihood".} =
  if length < 1 or values == nil: return -1.0e300
  let count = values[0]
  if count < 1 or count > MaxCount or length != 1 + 2 * csize_t(count): return -1.0e300
  var total = 0.0
  for i in 0 ..< int(count):
    let actualScaled = values[1 + i]
    let predictedScaled = values[1 + int(count) + i]
    if actualScaled < 0 or actualScaled > 1_000_000 or predictedScaled < 1 or predictedScaled > 999_999: return -1.0e300
    let actual = float64(actualScaled) / Scale
    let predicted = float64(predictedScaled) / Scale
    total += -actual * ln(predicted) - (1.0 - actual) * ln(1.0 - predicted)
  total / float64(count)
