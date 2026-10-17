import math

const MaxCount = 64
const MaxInputLength = 130
const InvalidResult = -1.0e300

proc kl_divergence_loss*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "kl_divergence_loss".} =
  if input.isNil or length < 2 or length > MaxInputLength: return InvalidResult
  let actualCountValue = input[0]
  let predictedCountValue = input[1]
  if actualCountValue < 0 or actualCountValue > MaxCount or predictedCountValue < 0 or predictedCountValue > MaxCount:
    return InvalidResult
  let actualCount = int(actualCountValue)
  let predictedCount = int(predictedCountValue)
  if int(length) != 2 + actualCount + predictedCount: return InvalidResult

  for index in 0 ..< actualCount:
    if input[2 + index] < 0 or input[2 + index] > 1_000_000: return InvalidResult
  for index in 0 ..< predictedCount:
    if input[2 + actualCount + index] < 0 or input[2 + actualCount + index] > 1_000_000: return InvalidResult

  let pairedCount = min(actualCount, predictedCount)
  var total = 0.0
  for index in 0 ..< pairedCount:
    let actual = float64(input[2 + index]) / 1_000_000.0 + 1e-5
    let predicted = float64(input[2 + actualCount + index]) / 1_000_000.0 + 1e-5
    total += actual * ln(actual / predicted)
  total
