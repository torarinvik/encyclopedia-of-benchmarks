## Stable recursive insertion sort over signed 64-bit values.
proc insertionSortPrefix(values: ptr UncheckedArray[int64], length: int) =
  if length <= 1: return
  insertionSortPrefix(values, length - 1)
  let key = values[length - 1]
  var position = length - 1
  while position > 0 and values[position - 1] > key:
    values[position] = values[position - 1]
    dec position
  values[position] = key

proc insertionSortRecursive*(values: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "insertion_sort_recursive".} =
  insertionSortPrefix(values, int(length))
