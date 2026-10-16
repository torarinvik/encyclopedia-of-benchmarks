proc minimum_waiting_time*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "minimum_waiting_time".} =
  if length > 64 or (length > 0 and values.isNil): return low(int64)
  if length == 0: return 0
  var durations: array[64, int64]
  for i in 0 ..< int(length):
    let value = values[i]
    if value < 0 or value > 1000: return low(int64)
    durations[i] = value
  for i in 1 ..< int(length):
    let key = durations[i]
    var j = i
    while j > 0 and durations[j - 1] > key:
      durations[j] = durations[j - 1]
      dec j
    durations[j] = key
  var total = 0'i64
  for i in 0 ..< int(length):
    total += durations[i] * int64(int(length) - i - 1)
  total
