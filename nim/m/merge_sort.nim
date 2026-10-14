## Stable bottom-up merge sort using caller-provided scratch storage.
proc merge_sort*(values, scratch: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "merge_sort".} =
  var width = csize_t(1)
  while width < length:
    var low = csize_t(0)
    while low < length:
      var middle = low + width
      if middle > length:
        middle = length
      var high = middle + width
      if high > length:
        high = length
      var left = low
      var right = middle
      var output = low
      while left < middle and right < high:
        if values[left] <= values[right]:
          scratch[output] = values[left]
          inc left
        else:
          scratch[output] = values[right]
          inc right
        inc output
      while left < middle:
        scratch[output] = values[left]
        inc left
        inc output
      while right < high:
        scratch[output] = values[right]
        inc right
        inc output
      for index in low ..< high:
        values[index] = scratch[index]
      low = high
    if width > length div 2:
      break
    width *= 2
