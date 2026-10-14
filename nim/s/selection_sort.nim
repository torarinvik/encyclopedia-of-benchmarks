## In-place selection sort for the shared sorting contract.
proc selection_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "selection_sort".} =
  var index = csize_t(0)
  while index + 1 < length:
    var minimum = index
    var probe = index + 1
    while probe < length:
      if values[probe] < values[minimum]:
        minimum = probe
      inc probe
    if minimum != index:
      let temporary = values[index]
      values[index] = values[minimum]
      values[minimum] = temporary
    inc index
