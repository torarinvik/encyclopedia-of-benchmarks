## Shell sort with a halving gap sequence for the shared contract.
proc shell_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "shell_sort".} =
  var gap = length div 2
  while gap > 0:
    var index = gap
    while index < length:
      let key = values[index]
      var position = index
      while position >= gap and values[position - gap] > key:
        values[position] = values[position - gap]
        position -= gap
      values[position] = key
      inc index
    gap = gap div 2
