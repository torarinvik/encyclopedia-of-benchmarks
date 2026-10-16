## Shell sort using the pinned Python 1.3 gap shrink factor.
proc shrink_shell_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "shrink_shell_sort".} =
  var gap = length
  while gap > 1:
    gap = csize_t(float64(gap) / 1.3)
    var index = gap
    while index < length:
      let key = values[index]
      var position = index
      while position >= gap and values[position - gap] > key:
        values[position] = values[position - gap]
        position -= gap
      values[position] = key
      inc index
