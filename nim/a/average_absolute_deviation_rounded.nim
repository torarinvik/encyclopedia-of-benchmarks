import std/math

proc roundTiesEven(value: float64): float64 =
  let lower = floor(value)
  let fraction = value - lower
  if fraction < 0.5: return lower
  if fraction > 0.5: return lower + 1.0
  if int64(lower) mod 2 == 0: return lower
  lower + 1.0

const MaxLength = 256
const MinValue = -2_147_483_648'i64
const MaxValue = 2_147_483_647'i64
const InvalidResult = -1.0e300
type I64Input = ptr UncheckedArray[int64]
proc average_absolute_deviation_rounded*(values: I64Input, length: csize_t): float64 {.cdecl, exportc: "average_absolute_deviation_rounded".} =
  if values == nil or length == 0 or length > MaxLength: return InvalidResult
  var sum = 0.0
  for index in 0 ..< int(length):
    let value = values[index]
    if value < MinValue or value > MaxValue: return InvalidResult
    sum += float64(value)
  let average = sum / float64(length)
  var deviations = 0.0
  for index in 0 ..< int(length):
    let value = float64(values[index])
    deviations += (if value >= average: value - average else: average - value)
  roundTiesEven((deviations / float64(length)) * 100.0) / 100.0
