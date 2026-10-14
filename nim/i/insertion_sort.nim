## Stable insertion sort for the shared mutable in-place sorting contract.
proc insertion_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "insertion_sort".} =
  var index = csize_t(1)
  while index < length:
    let key = values[index]
    var position = index
    while position > 0 and values[position - 1] > key:
      values[position] = values[position - 1]
      dec position
    values[position] = key
    inc index
