## Copy positive list values, then scan each mirrored twin pair.
const MaxLength = 1024

proc maximum_twin_sum_of_linked_list*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "maximum_twin_sum_of_linked_list".} =
  if values == nil or length < 2 or length > MaxLength or length mod 2 != 0: return -1
  let n = int(length)
  var copied: array[MaxLength, int32]
  for index in 0 ..< n:
    if values[index] < 1 or values[index] > 100000: return -1
    copied[index] = int32(values[index])
  var maximum = 0'i64
  for index in 0 ..< n div 2:
    let twinSum = int64(copied[index]) + int64(copied[n - index - 1])
    if twinSum > maximum: maximum = twinSum
  maximum
