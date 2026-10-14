## Stable odd-even transposition sort for the shared sorting contract.
proc odd_even_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "odd_even_sort".} =
  if length < 2:
    return
  var swapped = true
  while swapped:
    swapped = false
    var index = csize_t(0)
    while index + 1 < length:
      if values[index] > values[index + 1]:
        let temporary = values[index]
        values[index] = values[index + 1]
        values[index + 1] = temporary
        swapped = true
      index += 2
    index = 1
    while index + 1 < length:
      if values[index] > values[index + 1]:
        let temporary = values[index]
        values[index] = values[index + 1]
        values[index + 1] = temporary
        swapped = true
      index += 2
