import std/math

proc fromFactor(code: float64): float64 =
  if code == 0.0: return 1.0
  if code == 1.0: return 0.0000098
  if code == 2.0: return 0.986923
  if code == 3.0: return 0.00986923
  if code == 4.0: return 9.86923
  if code == 5.0: return 0.068046
  if code == 6.0: return 0.0334211
  if code == 7.0: return 0.00131579
  0.0

proc toFactor(code: float64): float64 =
  if code == 0.0: return 1.0
  if code == 1.0: return 101325.0
  if code == 2.0: return 1.01325
  if code == 3.0: return 101.325
  if code == 4.0: return 0.101325
  if code == 5.0: return 14.6959
  if code == 6.0: return 29.9213
  if code == 7.0: return 760.0
  0.0

proc pressure_conversions*(value, fromCode, toCode: float64): float64
    {.cdecl, exportc: "pressure_conversions".} =
  if classify(value) == fcNan or classify(value) == fcInf or classify(value) == fcNegInf or
      value < -1_000_000.0 or value > 1_000_000.0:
    return -1.0
  let source = fromFactor(fromCode)
  let target = toFactor(toCode)
  if source == 0.0 or target == 0.0: return -1.0
  let scaled = value * source
  scaled * target
