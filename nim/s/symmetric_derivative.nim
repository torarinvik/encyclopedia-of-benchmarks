import math

const MinXNanounits = -6300000000'i64
const MaxXNanounits = 6300000000'i64
const DefaultStep = 1.0e-10
const InvalidResult = -1.0e300

proc symmetric_derivative*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "symmetric_derivative".} =
  if values == nil or length != 2: return InvalidResult
  let functionId = values[0]
  let xNanounits = values[1]
  if (functionId != 0 and functionId != 1) or xNanounits < MinXNanounits or xNanounits > MaxXNanounits:
    return InvalidResult

  let x = float64(xNanounits) / 1_000_000_000.0
  let upper = if functionId == 0: sin(x + DefaultStep) else: exp(x + DefaultStep)
  let lower = if functionId == 0: sin(x - DefaultStep) else: exp(x - DefaultStep)
  (upper - lower) / (2.0 * DefaultStep)
