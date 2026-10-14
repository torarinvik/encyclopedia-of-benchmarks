## Lomuto quicksort; recurse into the smaller partition to bound stack depth.
proc partition(values: ptr UncheckedArray[int64], low, high: csize_t): csize_t =
  let pivot = values[high - 1]
  var boundary = low
  for scan in low ..< high - 1:
    if values[scan] <= pivot:
      swap(values[boundary], values[scan])
      inc boundary
  swap(values[boundary], values[high - 1])
  boundary

proc quickSortRange(values: ptr UncheckedArray[int64], lowValue, highValue: csize_t) =
  var low = lowValue
  var high = highValue
  while high - low > 1:
    let pivot = partition(values, low, high)
    let rightStart = pivot + 1
    if pivot - low < high - rightStart:
      quickSortRange(values, low, pivot)
      low = rightStart
    else:
      quickSortRange(values, rightStart, high)
      high = pivot

proc quick_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "quick_sort".} =
  if length > 1:
    quickSortRange(values, 0, length)
