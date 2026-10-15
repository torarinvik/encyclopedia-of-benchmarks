## Sum a bounded array of nonnegative signed integers.

proc array_sum*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "array_sum".} =
  if values == nil or length < 1: return -1
  let countValue = values[0]
  if countValue < 0 or countValue > 1024: return -1
  let count = int(countValue)
  if int(length) != count + 1: return -1
  var sum: int64 = 0
  for i in 0 ..< count:
    let value = values[i + 1]
    if value < 0 or value > 1000000000: return -1
    sum += value
  sum
