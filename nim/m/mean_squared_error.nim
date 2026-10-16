const MaxCount = 256'i64
const MaxParsedCount = 257'i64
const MaxSample = 1_000_000'i64
const MaxInputLength = 515
const InvalidResult = -1.0e300

proc mean_squared_error*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "mean_squared_error".} =
  if values == nil or length < 1 or length > MaxInputLength: return InvalidResult
  let countValue = values[0]
  if countValue < 0 or countValue > MaxParsedCount: return InvalidResult
  if length != csize_t(1 + 2 * countValue) or countValue == 0 or countValue > MaxCount:
    return InvalidResult
  let count = int(countValue)
  for index in 0 ..< count * 2:
    if values[1 + index] < -MaxSample or values[1 + index] > MaxSample:
      return InvalidResult
  var total = 0.0
  for index in 0 ..< count:
    let difference = float64(values[1 + index]) / 1_000_000.0 -
                     float64(values[1 + count + index]) / 1_000_000.0
    total += difference * difference
  total / float64(count)
