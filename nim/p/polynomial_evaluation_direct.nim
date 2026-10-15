## Bounded integer port of the pinned direct-power polynomial routine.
const InvalidResult = low(int64)

proc integerPower(base: int64, exponent: int): int64 =
  var result = 1'i64
  for _ in 0 ..< exponent:
    result *= base
  result

proc polynomial_evaluation_direct*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "polynomial_evaluation_direct".} =
  if length < 2 or length > 10 or values.isNil: return InvalidResult
  let count = values[0]
  let x = values[1]
  if count < 0 or count > 8 or length != csize_t(count + 2): return InvalidResult
  if x < -10 or x > 10: return InvalidResult
  for index in 0 ..< int(count):
    let coefficient = values[index + 2]
    if coefficient < -1000 or coefficient > 1000: return InvalidResult
  var result = 0'i64
  for index in 0 ..< int(count):
    result += values[index + 2] * integerPower(x, index)
  result
