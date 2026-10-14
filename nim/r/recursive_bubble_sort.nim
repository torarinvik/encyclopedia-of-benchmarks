## Recursive bubble sort for the shared signed 64-bit benchmark contract.
proc recursive_bubble_sort_range(values: ptr UncheckedArray[int64], length: csize_t) =
  if length < 2:
    return
  var index = csize_t(0)
  while index + 1 < length:
    if values[index] > values[index + 1]:
      let temporary = values[index]
      values[index] = values[index + 1]
      values[index + 1] = temporary
    inc index
  recursive_bubble_sort_range(values, length - 1)

proc recursive_bubble_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "recursive_bubble_sort".} =
  recursive_bubble_sort_range(values, length)
