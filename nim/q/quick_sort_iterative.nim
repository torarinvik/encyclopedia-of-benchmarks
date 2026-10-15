proc quickSortIterativePartition(values: ptr UncheckedArray[int64], low, high: csize_t): csize_t =
  let pivot = values[high - 1]
  var boundary = low
  var scan = low
  while scan < high - 1:
    if values[scan] <= pivot:
      swap(values[boundary], values[scan])
      inc boundary
    inc scan
  swap(values[boundary], values[high - 1])
  boundary

proc quick_sort_iterative*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "quick_sort_iterative".} =
  if length < 2:
    return

  var stackLow: array[128, csize_t]
  var stackHigh: array[128, csize_t]
  var stackSize = csize_t(0)
  var low = csize_t(0)
  var high = length
  while true:
    while high - low > 1:
      let pivot = quickSortIterativePartition(values, low, high)
      let leftSize = pivot - low
      let rightSize = high - pivot - 1
      if leftSize < rightSize:
        if rightSize > 1:
          stackLow[stackSize] = pivot + 1
          stackHigh[stackSize] = high
          inc stackSize
        high = pivot
      else:
        if leftSize > 1:
          stackLow[stackSize] = low
          stackHigh[stackSize] = pivot
          inc stackSize
        low = pivot + 1
    if stackSize == 0:
      break
    dec stackSize
    low = stackLow[stackSize]
    high = stackHigh[stackSize]
