import std/math

const MaxValue = 1e100

proc unitExponent(code: float64): int =
  if code == 0.0: return 0
  if code == 1.0: return 3
  if code == 2.0: return 6
  if code == 3.0: return 9
  if code == 4.0: return 12
  if code == 5.0: return 15
  if code == 6.0: return 18
  if code == 7.0: return 21
  if code == 8.0: return 24
  -1

## Preserve the source formula and operation order: value * 10^(from - to).
proc order_of_magnitude_conversion*(value, fromUnitCode, toUnitCode: float64): float64
    {.cdecl, exportc: "order_of_magnitude_conversion".} =
  if classify(value) == fcNan or value < -MaxValue or value > MaxValue:
    return -1.0
  let fromExp = unitExponent(fromUnitCode)
  let toExp = unitExponent(toUnitCode)
  if fromExp < 0 or toExp < 0: return -1.0
  value * pow(10.0, float64(fromExp - toExp))
