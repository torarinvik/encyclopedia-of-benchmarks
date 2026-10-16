import math
const MaxInputLength = 2050
const InvalidResult = -1.0e300
proc categorical_cross_entropy*(values: ptr UncheckedArray[int64], length: csize_t): float64 {.cdecl, exportc: "categorical_cross_entropy".} =
  if values == nil or length < 2 or length > MaxInputLength: return InvalidResult
  let batchValue = values[0]
  let classesValue = values[1]
  if batchValue < 1 or batchValue > 64 or classesValue < 2 or classesValue > 16: return InvalidResult
  let batch = int(batchValue)
  let classes = int(classesValue)
  let cells = batch * classes
  if length != csize_t(2 + 2 * cells): return InvalidResult
  for row in 0 ..< batch:
    var labelSum: int64 = 0
    var probabilitySum: int64 = 0
    for column in 0 ..< classes:
      let index = row * classes + column
      let label = values[2 + index]
      let probability = values[2 + cells + index]
      if label != 0 and label != 1: return InvalidResult
      if probability < 0 or probability > 1_000_000: return InvalidResult
      labelSum += label
      probabilitySum += probability
    if labelSum != 1 or probabilitySum != 1_000_000: return InvalidResult
  var total = 0.0
  for row in 0 ..< batch:
    var rowLoss = 0.0
    for column in 0 ..< classes:
      let index = row * classes + column
      let label = float64(values[2 + index])
      var probability = float64(values[2 + cells + index]) / 1_000_000.0
      if probability < 1e-15: probability = 1e-15
      if probability > 1.0: probability = 1.0
      rowLoss -= label * ln(probability)
    total += rowLoss
  total
