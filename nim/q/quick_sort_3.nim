proc quickSort3Range(values: ptr UncheckedArray[int64], lowValue, highValue: csize_t) =
  var low = lowValue
  var high = highValue
  while high - low > 1:
    let pivot = values[high - 1]
    var less = low
    var scan = low
    var greater = high
    while scan < greater:
      if values[scan] < pivot:
        swap(values[less], values[scan])
        inc less
        inc scan
      elif values[scan] > pivot:
        dec greater
        swap(values[scan], values[greater])
      else:
        inc scan
    if less - low < high - greater:
      quickSort3Range(values, low, less)
      low = greater
    else:
      quickSort3Range(values, greater, high)
      high = less

proc quick_sort_3*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "quick_sort_3".} =
  if length > 1:
    quickSort3Range(values, 0, length)
