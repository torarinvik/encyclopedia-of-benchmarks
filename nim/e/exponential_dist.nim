import std/math

const MaxRateMicro = 1_000_000_000'i64
const InvalidResult = -1.0e300

proc exponential_dist*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "exponential_dist".} =
  if values == nil or length != 2: return InvalidResult
  let operation = values[0]
  let rateMicro = values[1]
  if operation < 0 or operation > 2 or rateMicro <= 0 or rateMicro > MaxRateMicro:
    return InvalidResult
  let rate = float64(rateMicro) / 1_000_000.0
  if operation == 1: return 1.0 / pow(rate, 2.0)
  1.0 / rate
