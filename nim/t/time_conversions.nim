import std/math

proc fma(first, second, third: float64): float64 {.importc: "fma", header: "<math.h>".}

proc secondsFactor(code: float64): float64 =
  if code == 0.0: return 1.0
  if code == 1.0: return 60.0
  if code == 2.0: return 3600.0
  if code == 3.0: return 86400.0
  if code == 4.0: return 604800.0
  if code == 5.0: return 2629800.0
  if code == 6.0: return 31557600.0
  0.0

proc inverseFactor(code: float64): float64 =
  if code == 0.0: return 1.0
  if code == 1.0: return 0.016666666666666666
  if code == 2.0: return 0.0002777777777777778
  if code == 3.0: return 0.000011574074074074073
  if code == 4.0: return 0.0000016534391534391535
  if code == 5.0: return 0.0000003802570537683474
  if code == 6.0: return 0.00000003168808781402895
  0.0

proc roundThreeTiesEven(value: float64): float64 =
  let scaled = value * 1000.0
  let lower = floor(scaled)
  let fraction = scaled - lower
  let residual = fma(value, 1000.0, -scaled)
  var rounded = lower
  if fraction > 0.5 or (fraction == 0.5 and (residual > 0.0 or (residual == 0.0 and int64(lower) mod 2 != 0))):
    rounded = lower + 1.0
  rounded / 1000.0

proc time_conversions*(timeValue, fromCode, toCode: float64): float64
    {.cdecl, exportc: "time_conversions".} =
  if classify(timeValue) == fcNan or classify(timeValue) == fcInf or classify(timeValue) == fcNegInf or
      timeValue < 0.0 or timeValue > 10000.0:
    return -1e300
  let source = secondsFactor(fromCode)
  let inverse = inverseFactor(toCode)
  if source == 0.0 or inverse == 0.0: return -1e300
  let scaled = timeValue * source
  roundThreeTiesEven(scaled * inverse)
