import std/math

const MaxValue = 1_000_000_000_000'i64

proc sourceScore(base, exponent: int64): float64 =
  if base == 0: return 0.0
  if exponent == 0: return 1.0
  float64(exponent) * log10(float64(base))

proc validComparisonDomain(baseA, exponentA, baseB, exponentB: int64): bool =
  exponentA == exponentB or
    (baseA == baseB and (baseA == 0 or ((exponentA == 0) == (exponentB == 0))))

proc largest_of_very_large_numbers*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "largest_of_very_large_numbers".} =
  if values.isNil or length != 4: return -2
  for i in 0 ..< 4:
    if values[i] < 0 or values[i] > MaxValue: return -2
  if not validComparisonDomain(values[0], values[1], values[2], values[3]): return -2
  let a = sourceScore(values[0], values[1])
  let b = sourceScore(values[2], values[3])
  if a > b: return 1
  if a < b: return -1
  0
