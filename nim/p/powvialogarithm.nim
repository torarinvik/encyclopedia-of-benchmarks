## Power through the pinned logarithm/exponential method.
import std/math

const InvalidResult = -1.0e300

proc powvialogarithm*(base, exponent: float64): float64 {.cdecl, exportc: "powvialogarithm".} =
  if base != base or exponent != exponent or base < -4.0 or base > 4.0 or
      exponent < -8.0 or exponent > 8.0 or floor(base) != base or floor(exponent) != exponent or
      (base == 0.0 and exponent <= 0.0) or
      ((base == 2.0 or base == -2.0) and exponent == -1.0):
    return InvalidResult

  var sign = 1.0
  let power = int64(exponent)
  if base < 0.0 and (power mod 2) != 0: sign = -1.0
  let logarithm = ln(abs(base))
  let exponential = exp(exponent * logarithm)
  let result = exponential * sign
  round(result)
