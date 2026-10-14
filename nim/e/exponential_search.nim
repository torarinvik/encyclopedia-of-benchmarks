## Exponential search in an ascending sequence for the shared benchmark contract.
proc binary_search_range(values: ptr UncheckedArray[int64], low_bound, high_bound: csize_t, target: int64): int64 =
  var low = low_bound
  var high = high_bound
  while low < high:
    let middle = low + (high - low) div 2
    let value = values[middle]
    if value == target:
      return int64(middle)
    if value < target:
      low = middle + 1
    else:
      high = middle
  return -1

proc exponential_search*(values: ptr UncheckedArray[int64], length: csize_t, target: int64): int64 {.cdecl, exportc: "exponential_search".} =
  if length == 0:
    return -1
  var upper = csize_t(1)
  while upper < length and values[upper] <= target:
    if upper > length div 2:
      upper = length
    else:
      upper *= 2
  return binary_search_range(values, upper div 2, upper, target)
