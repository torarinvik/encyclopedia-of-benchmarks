import std/math

proc toPascalFactor(code: float64): float64 =
  if code == 0.0: return 1.0
  if code == 1.0: return 1000.0
  if code == 2.0: return 1_000_000.0
  if code == 3.0: return 100_000.0
  if code == 4.0: return 101_325.0
  if code == 5.0: return 6894.757293168
  0.0

proc pressure*(value, fromUnitCode, toUnitCode: float64): float64
    {.cdecl, exportc: "pressure".} =
  if classify(value) == fcNan or classify(value) == fcInf or classify(value) == fcNegInf or
      value < -1_000_000.0 or value > 1_000_000.0:
    return -1.0
  let fromFactor = toPascalFactor(fromUnitCode)
  let toFactor = toPascalFactor(toUnitCode)
  if fromFactor == 0.0 or toFactor == 0.0: return -1.0
  let pascals = value * fromFactor
  pascals / toFactor
