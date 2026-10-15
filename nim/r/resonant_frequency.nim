## LC resonant frequency over bounded integer-valued inputs.
import std/math

proc resonant_frequency*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "resonant_frequency".} =
  if values == nil or length != 2: return -1.0e300
  let inductance = values[0]
  let capacitance = values[1]
  if inductance < 1 or inductance > 1000 or capacitance < 1 or capacitance > 1000: return -1.0e300
  const pi = 3.14159265358979323846
  1.0 / (2.0 * pi * sqrt(float64(inductance) * float64(capacitance)))
