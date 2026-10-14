## Binary search in an ascending sequence for the shared benchmark contract.
proc binary_search*(values: ptr UncheckedArray[int64], length: csize_t, target: int64): int64 {.cdecl, exportc: "binary_search".} =
  var low: csize_t = 0
  var high: csize_t = length

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
