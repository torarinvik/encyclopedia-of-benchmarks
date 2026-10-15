## Return the absent value from 0 through the number of supplied values.
const MaxValues = 1024

proc missing_number*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "missing_number".} =
  if length > csize_t(MaxValues) or (length != 0 and values == nil): return -1
  var seen: array[MaxValues + 1, bool]
  var actualSum = 0'i64
  for index in 0 ..< int(length):
    let value = values[index]
    if value < 0 or value > int64(length): return -1
    if seen[int(value)]: return -1
    seen[int(value)] = true
    actualSum += value
  let n = int64(length)
  n * (n + 1) div 2 - actualSum
