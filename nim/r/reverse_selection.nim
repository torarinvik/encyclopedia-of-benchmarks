proc reverse_selection*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "reverse_selection".} =
  if length < 2:
    return
  var start = csize_t(0)
  while start + 1 < length:
    var minimum = start
    var scan = start + 1
    while scan < length:
      if values[scan] < values[minimum]:
        minimum = scan
      inc scan
    var left = start
    var right = minimum
    while left < right:
      swap(values[left], values[right])
      inc left
      dec right
    inc start
