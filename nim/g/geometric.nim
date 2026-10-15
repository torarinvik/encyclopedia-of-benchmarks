import std/math

const InvalidResult = -1.0e300

## Operation 0 tests a geometric sequence; operation 1 computes its mean.
proc geometric*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "geometric".} =
  if values == nil or length < 2: return InvalidResult
  let operation = values[0]
  let count = int(length) - 1
  if operation == 0:
    if count > 16: return InvalidResult
    for i in 1 ..< int(length):
      if values[i] < -100 or values[i] > 100: return InvalidResult
    if count == 1: return 1.0
    if values[1] == 0: return 0.0
    let commonRatio = float64(values[2]) / float64(values[1])
    for i in 0 ..< count - 1:
      if values[i + 1] == 0: return 0.0
      if float64(values[i + 2]) / float64(values[i + 1]) != commonRatio: return 0.0
    return 1.0
  if operation == 1:
    if count > 7: return InvalidResult
    var product = 1'i64
    for i in 1 ..< int(length):
      if values[i] < 0 or values[i] > 100: return InvalidResult
      product *= values[i]
    return pow(float64(product), 1.0 / float64(count))
  InvalidResult
