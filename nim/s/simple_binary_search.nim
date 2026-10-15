## Recursive binary search membership check over an ascending sequence.
proc simple_binary_search_range(values: ptr UncheckedArray[int64], low, high: csize_t, target: int64): int64 =
  if low >= high:
    return 0

  let middle = low + (high - low) div 2
  if values[middle] == target:
    return 1
  if target < values[middle]:
    return simple_binary_search_range(values, low, middle, target)
  return simple_binary_search_range(values, middle + 1, high, target)

proc simple_binary_search*(values: ptr UncheckedArray[int64], length: csize_t, target: int64): int64 {.cdecl, exportc: "simple_binary_search".} =
  simple_binary_search_range(values, 0, length, target)
