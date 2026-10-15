## Bounded integer port of the pinned floating-point Horner routine.
const InvalidResult = low(int64)

proc polynomial_evaluation*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "polynomial_evaluation".} =
  if length < 2 or length > 10 or values.isNil: return InvalidResult
  let count = values[0]
  let x = values[1]
  if count < 0 or count > 8 or length != csize_t(count + 2): return InvalidResult
  if x < -10 or x > 10: return InvalidResult
  var index = 0
  while index < int(count):
    let coefficient = values[index + 2]
    if coefficient < -1000 or coefficient > 1000: return InvalidResult
    inc index
  var result = 0'i64
  index = int(count)
  while index > 0:
    dec index
    result = result * x + values[index + 2]
  result
