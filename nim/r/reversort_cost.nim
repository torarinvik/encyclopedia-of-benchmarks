proc reversort_cost*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "reversort_cost".} =
  if length > 256: return -1
  var working: array[256, int64]
  for index in 0 ..< int(length):
    if values[index] < low(int32).int64 or values[index] > high(int32).int64: return -1
    working[index] = values[index]
  var cost = 0'i64
  for index in 0 ..< max(0, int(length) - 1):
    var minimum = index
    for probe in index + 1 ..< int(length):
      if working[probe] < working[minimum]: minimum = probe
    var left = index
    var right = minimum
    while left < right:
      let temporary = working[left]
      working[left] = working[right]
      working[right] = temporary
      inc left
      dec right
    cost += int64(minimum - index + 1)
  cost
