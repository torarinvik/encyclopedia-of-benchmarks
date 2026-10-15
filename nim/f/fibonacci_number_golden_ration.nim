import std/math

proc fibonacci_number_golden_ration*(input: int64): int64 {.cdecl, exportc: "fibonacci_number_golden_ration".} =
  if input < 0 or input > 70: return -1
  if input <= 1: return input

  let sqrt5 = sqrt(5.0)
  let phi = (1.0 + sqrt5) / 2.0
  let psi = (1.0 - sqrt5) / 2.0
  let result = (pow(phi, float64(input)) - pow(psi, float64(input))) / sqrt5
  int64(floor(result + 0.5))
