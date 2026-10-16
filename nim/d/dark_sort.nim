proc dark_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "dark_sort".} =
  if length < 2: return
  var maximum = values[0]
  var index = 1.csize_t
  while index < length:
    if values[index] > maximum: maximum = values[index]
    inc index
  var counts: array[129, int64]
  index = 0
  while index < length:
    inc counts[values[index].int]
    inc index
  var output = 0.csize_t
  var value = 0
  while value <= maximum:
    while counts[value] > 0:
      values[output] = value.int64
      inc output
      dec counts[value]
    inc value
