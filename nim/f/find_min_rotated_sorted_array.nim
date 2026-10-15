## Return the minimum in a rotation of a strictly increasing i64 array.
proc find_min_rotated_sorted_array*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "find_min_rotated_sorted_array".} =
  if length < 1 or length > 256 or values.isNil: return -1
  var low = 0
  var high = int(length - 1)
  while low < high:
    let middle = low + (high - low) div 2
    if values[middle] <= values[high]: high = middle
    else: low = middle + 1
  values[low]
