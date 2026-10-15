## Find the peak of a strict mountain array with binary search.
const MaxArrayLength = 100000

proc peak_index_in_mountain_array*(values: ptr UncheckedArray[int64],
                                   length: csize_t): int64
    {.cdecl, exportc: "peak_index_in_mountain_array".} =
  if values.isNil or length < 3 or length > csize_t(MaxArrayLength): return -1
  var low = 0
  var high = int(length) - 1
  while low < high:
    let middle = low + (high - low) div 2
    if values[middle] < values[middle + 1]: low = middle + 1
    else: high = middle
  if low == 0 or low + 1 == int(length): return -1
  int64(low)
