## Estimate altitude from pressure using the pinned source formula.
import std/math

proc altitude_pressure*(pressure: float64): float64 {.cdecl, exportc: "altitude_pressure".} =
  if pressure < 0.0 or pressure > 101325.0: return -1.0
  if pressure == 0.0: return 44330.0
  let exponent = 1.0 / 5.5255
  44330.0 * (1.0 - pow(pressure / 101325.0, exponent))
