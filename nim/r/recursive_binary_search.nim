## Recursive binary search in an ascending sequence for the shared contract.
proc recursive_binary_search_range(values: ptr UncheckedArray[int64], low, high: csize_t, target: int64): int64 =
  if low >= high:
    return -1

  let middle = low + (high - low) div 2
  if values[middle] == target:
    return int64(middle)
  if target < values[middle]:
    return recursive_binary_search_range(values, low, middle, target)
  return recursive_binary_search_range(values, middle + 1, high, target)

proc recursive_binary_search*(values: ptr UncheckedArray[int64], length: csize_t, target: int64): int64 {.cdecl, exportc: "recursive_binary_search".} =
  recursive_binary_search_range(values, 0, length, target)
