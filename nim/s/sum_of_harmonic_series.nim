import std/math
const InvalidResult = -1.0e300
proc sum_of_harmonic_series*(firstTerm, commonDifference, numberOfTerms: float64): float64 {.cdecl, exportc: "sum_of_harmonic_series".} =
  if classify(firstTerm) == fcNan or classify(firstTerm) == fcInf or classify(firstTerm) == fcNegInf or
      classify(commonDifference) == fcNan or classify(commonDifference) == fcInf or classify(commonDifference) == fcNegInf or
      firstTerm <= 0.0 or firstTerm > 1000.0 or commonDifference < 0.0 or commonDifference > 1000.0 or
      numberOfTerms < 1.0 or numberOfTerms > 256.0 or floor(numberOfTerms) != numberOfTerms: return InvalidResult
  let count = int(numberOfTerms)
  var arithmeticTerm = 1.0 / firstTerm
  var total = 0.0
  for index in 0 ..< count:
    total += 1.0 / arithmeticTerm
    if index + 1 < count: arithmeticTerm += commonDifference
  total
