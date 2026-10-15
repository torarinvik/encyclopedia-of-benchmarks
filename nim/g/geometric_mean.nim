import std/math

const MaxLength = 6
const MaxAbsValue = 100'i64
const InvalidResult = -1.0e300

type I64Input = ptr UncheckedArray[int64]

proc geometric_mean*(values: I64Input, length: csize_t): float64 {.cdecl, exportc: "geometric_mean".} =
  if values == nil or length == 0 or length > MaxLength: return InvalidResult
  var product = 1'i64
  for index in 0 ..< int(length):
    let value = values[index]
    if value < -MaxAbsValue or value > MaxAbsValue: return InvalidResult
    product *= value
  if product < 0 and length mod 2 == 0: return InvalidResult
  var root = pow(abs(float64(product)), 1.0 / float64(length))
  let rounded = floor(root + 0.5)
  var roundedPower = 1'i64
  for _ in 0 ..< int(length): roundedPower *= int64(rounded)
  if (product >= 0 and roundedPower == product) or (product < 0 and length mod 2 == 1 and -roundedPower == product):
    root = float64(rounded)
  if product < 0: root = -root
  root
