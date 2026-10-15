## Binary search over a monotone sequence in either direction.
proc order_agnostic_binary_search*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "order_agnostic_binary_search".} =
  if values == nil or length < 3 or length > 100001: return -1
  let target = values[0]
  let count = values[1]
  if target < int64(low(int32)) or target > int64(high(int32)) or count < 1 or count > 99999: return -1
  if length != csize_t(count) + 2: return -1
  let ascending = values[2] < values[count + 1]
  var start = 0'i64
  var right = count - 1
  while start <= right:
    let middle = start + (right - start) div 2
    let value = values[middle + 2]
    if value == target: return middle
    if ascending:
      if value < target: start = middle + 1
      else: right = middle - 1
    else:
      if value > target: start = middle + 1
      else: right = middle - 1
  return -1
