const InvalidResult = low(int64)
const MaxValues = 256

proc max_values*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "max_values".} =
  if values == nil or length < 1 or length > MaxValues + 1: return InvalidResult
  let count = values[0]
  if count < 1 or count > MaxValues or length != csize_t(count + 1): return InvalidResult
  var result = values[1]
  if result < int64(low(int32)) or result > int64(high(int32)): return InvalidResult
  for index in 2 ..< int(length):
    let value = values[index]
    if value < int64(low(int32)) or value > int64(high(int32)): return InvalidResult
    if value > result: result = value
  result
