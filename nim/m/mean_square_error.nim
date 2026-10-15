const MaxLength = 256
const InvalidResult = -1.0e300

proc mean_square_error*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "mean_square_error".} =
  if values == nil or length < 3 or length > csize_t(2 * MaxLength + 1): return InvalidResult
  let countValue = values[0]
  if countValue < 1 or countValue > MaxLength or length != csize_t(2 * countValue + 1): return InvalidResult
  let count = int(countValue)
  var errorSum = 0.0
  for index in 0 ..< count:
    let predicted = values[index + 1]
    let expected = values[index + 1 + count]
    if predicted < -1_000_000 or predicted > 1_000_000 or expected < -1_000_000 or expected > 1_000_000:
      return InvalidResult
    let difference = float64(expected - predicted)
    errorSum += difference * difference
  return errorSum / float64(count)
