## Cross-entropy loss with source-ordered intermediate terms and summation.
import math

const MaxCount = 64
const Scale = 1_000_000.0

proc cross_entropy_loss*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "cross_entropy_loss".} =
  if length < 1 or values == nil: return -1.0e300
  let count = values[0]
  if count < 1 or count > MaxCount or length != 1 + 2 * csize_t(count): return -1.0e300
  var terms: array[MaxCount, float64]
  for i in 0 ..< int(count):
    let actualScaled = values[1 + i]
    let predictedScaled = values[1 + int(count) + i]
    if actualScaled < 0 or actualScaled > 1_000_000 or
        predictedScaled < 1 or predictedScaled > 1_000_000: return -1.0e300
    let actual = float64(actualScaled) / Scale
    let predicted = float64(predictedScaled) / Scale
    terms[i] = -actual * ln(predicted)
  var total = 0.0
  for i in 0 ..< int(count): total += terms[i]
  total
