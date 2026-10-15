import std/math

const MaxLength = 64
const MaxAbsValue = 1_000_000'i64
const InvalidResult = -1.0e300

type I64Input = ptr UncheckedArray[int64]

proc standard_deviation*(values: I64Input, length: csize_t): float64 {.cdecl, exportc: "standard_deviation".} =
  if values == nil or length == 0 or length > MaxLength: return InvalidResult
  var sum = 0.0
  for index in 0 ..< int(length):
    let value = values[index]
    if value < -MaxAbsValue or value > MaxAbsValue: return InvalidResult
    sum += float64(value)
  let average = sum / float64(length)
  var squaredDeviations = 0.0
  for index in 0 ..< int(length):
    let difference = float64(values[index]) - average
    squaredDeviations += pow(difference, 2.0)
  sqrt(squaredDeviations / float64(length))
