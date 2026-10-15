const InvalidResult = -1.0e300

type I64Input = ptr UncheckedArray[int64]

proc sum_of_arithmetic_series*(packed: I64Input, length: csize_t): float64 {.cdecl, exportc: "sum_of_arithmetic_series".} =
  if packed == nil or length != 3: return InvalidResult
  let a = packed[0]
  let d = packed[1]
  let n = packed[2]
  if a < -1000 or a > 1000 or d < -1000 or d > 1000 or n < 1 or n > 1000: return InvalidResult
  let result = n * (2 * a + (n - 1) * d) div 2
  float64(result)
