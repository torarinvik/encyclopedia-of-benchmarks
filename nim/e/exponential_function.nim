import math

proc exponential_function*(power: float64, termCount: float64): float64 {.cdecl, exportc: "exponential_function".} =
  if not (power >= -10.0 and power <= 10.0 and termCount >= 0.0 and termCount <= 32.0): return -1.0e300
  let n = int(termCount)
  if float64(n) != termCount: return -1.0e300
  if n == 0: return 1.0

  var output = 0.0
  var factorial = 1.0
  for i in 0 ..< n:
    output += pow(power, float64(i)) / factorial
    factorial *= float64(i + 1)
  output
