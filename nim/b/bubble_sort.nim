## Stable bubble sort for the shared mutable in-place sorting contract.
proc bubble_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "bubble_sort".} =
  if length < 2:
    return

  var endIndex = length
  while endIndex > 1:
    var swapped = false
    var index = csize_t(0)
    while index + 1 < endIndex:
      if values[index] > values[index + 1]:
        let temporary = values[index]
        values[index] = values[index + 1]
        values[index + 1] = temporary
        swapped = true
      inc index
    if not swapped:
      break
    dec endIndex
