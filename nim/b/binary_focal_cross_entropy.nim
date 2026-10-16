import math
const MaxInputLength = 513
const InvalidResult = -1.0e300
proc binary_focal_cross_entropy*(values: ptr UncheckedArray[int64], length: csize_t): float64 {.cdecl, exportc: "binary_focal_cross_entropy".} =
  if values == nil or length < 1 or length > MaxInputLength: return InvalidResult
  let countValue = values[0]
  if countValue < 1 or countValue > 256 or length != csize_t(1 + 2 * countValue): return InvalidResult
  let count = int(countValue)
  for index in 0 ..< count:
    let label = values[1 + index]
    let probability = values[1 + count + index]
    if (label != 0 and label != 1) or probability < 0 or probability > 1_000_000: return InvalidResult
  var total = 0.0
  for index in 0 ..< count:
    let label = float64(values[1 + index])
    var probability = float64(values[1 + count + index]) / 1_000_000.0
    if probability < 1e-15: probability = 1e-15
    if probability > 1.0 - 1e-15: probability = 1.0 - 1e-15
    let negativeProbability = 1.0 - probability
    total -= 0.25 * negativeProbability * negativeProbability * label * ln(probability) +
             0.75 * probability * probability * (1.0 - label) * ln(negativeProbability)
  total / float64(count)
