import std/math

const InvalidResult = -1.0e300

proc hickerson_almost_integer*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "hickerson_almost_integer".} =
  if values == nil or length != 1: return InvalidResult
  let n = values[0]
  if n < 1 or n > 17: return InvalidResult
  let logTwo = ln(2.0)
  var value = 1.0 / (2.0 * logTwo * logTwo)
  for index in 2 .. n:
    value = (float64(index) / logTwo) * value
  value
