## Stable full-range bidirectional adjacent-swap sort.
proc cocktail_shaker_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "cocktail_shaker_sort".} =
  if length < 2:
    return
  while true:
    var swapped = false
    for index in 0 ..< (length - 1):
      if values[index] > values[index + 1]:
        swap(values[index], values[index + 1])
        swapped = true
    if not swapped:
      break
    swapped = false
    var index = length - 1
    while index > 0:
      if values[index - 1] > values[index]:
        swap(values[index - 1], values[index])
        swapped = true
      dec index
    if not swapped:
      break
