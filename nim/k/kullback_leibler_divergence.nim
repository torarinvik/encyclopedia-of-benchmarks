import math

const MaxCount = 64
const MaxInputLength = 1 + 2 * MaxCount
const Scale = 1_000_000.0
const InvalidResult = -1.0e300

proc kullback_leibler_divergence*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "kullback_leibler_divergence".} =
  if values.isNil or length < 3 or length > MaxInputLength: return InvalidResult
  let countValue = values[0]
  if countValue < 1 or countValue > MaxCount: return InvalidResult
  let count = int(countValue)
  if length != csize_t(1 + 2 * count): return InvalidResult

  for i in 0 ..< count:
    let target = values[1 + i]
    let prediction = values[1 + count + i]
    if target < 0 or target > 1_000_000 or prediction < 0 or prediction > 1_000_000 or
        (target > 0 and prediction == 0): return InvalidResult

  var total = 0.0
  for i in 0 ..< count:
    let targetScaled = values[1 + i]
    if targetScaled == 0: continue
    let predictionScaled = values[1 + count + i]
    let target = float64(targetScaled) / Scale
    let prediction = float64(predictionScaled) / Scale
    total += target * ln(target / prediction)
  total
