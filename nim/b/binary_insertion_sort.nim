## Stable binary insertion sort using an upper-bound search for each key.
proc binary_insertion_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "binary_insertion_sort".} =
  var index = csize_t(1)
  while index < length:
    let key = values[index]
    var low = csize_t(0)
    var high = index
    while low < high:
      let middle = low + (high - low) div 2
      if values[middle] <= key:
        low = middle + 1
      else:
        high = middle
    var position = index
    while position > low:
      values[position] = values[position - 1]
      dec position
    values[low] = key
    inc index
