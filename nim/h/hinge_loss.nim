const MaxCount = 256
const MaxInputLength = 1 + 2 * MaxCount
const PredictionScale = 1_000_000.0
const InvalidResult = -1.0e300

type I64Input = ptr UncheckedArray[int64]

proc hinge_loss*(values: I64Input, length: csize_t): float64 {.cdecl, exportc: "hinge_loss".} =
  if values == nil or length < 3 or length > MaxInputLength: return InvalidResult
  let countValue = values[0]
  if countValue < 1 or countValue > MaxCount: return InvalidResult
  let count = int(countValue)
  if length != csize_t(1 + 2 * count): return InvalidResult

  var total = 0.0
  for index in 0 ..< count:
    let label = values[1 + index]
    let scoreScaled = values[1 + count + index]
    if (label != -1 and label != 1) or scoreScaled < -1_000_000 or scoreScaled > 1_000_000:
      return InvalidResult
    let prediction = float64(scoreScaled) / PredictionScale
    let loss = 1.0 - float64(label) * prediction
    if loss > 0.0: total += loss
  total / float64(count)
