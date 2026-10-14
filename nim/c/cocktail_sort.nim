## Stable bidirectional bubble sort for signed 64-bit values.
proc cocktail_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "cocktail_sort".} =
  var start = csize_t(0)
  var finish = length
  while start < finish:
    var swapped = false
    var index = start
    while index + 1 < finish:
      if values[index] > values[index + 1]:
        swap(values[index], values[index + 1])
        swapped = true
      inc index
    if not swapped:
      break
    dec finish
    swapped = false
    index = finish
    while index > start:
      if values[index - 1] > values[index]:
        swap(values[index - 1], values[index])
        swapped = true
      dec index
    inc start
    if not swapped:
      break
