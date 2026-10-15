import std/[math]

const InvalidResult = -1.0e300

proc nth_root*(radicand, index, tolerance: float64): float64 {.cdecl, exportc: "nth_root".} =
  if classify(radicand) in {fcNan, fcInf, fcNegInf} or classify(index) in {fcNan, fcInf, fcNegInf} or classify(tolerance) in {fcNan, fcInf, fcNegInf} or
      radicand < 0.5 or radicand > 1000.0 or index < 3.0 or index > 8.0 or
      index != floor(index) or tolerance < 1.0e-12 or tolerance > 1.0e-3:
    return InvalidResult
  var newApproximation = radicand
  var oldApproximation = newApproximation + tolerance + 0.1
  while tolerance <= abs(oldApproximation - newApproximation):
    oldApproximation = newApproximation
    let firstSummand = (index - 1.0) / index * oldApproximation
    let secondSummand = radicand / (index * pow(oldApproximation, index - 1.0))
    newApproximation = firstSummand + secondSummand
  newApproximation
