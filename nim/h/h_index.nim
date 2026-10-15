## Find the greatest h for which at least h citations are >= h.
proc h_index*(citations: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "h_index".} =
  if length > 5000:
    return -1
  var index = csize_t(0)
  while index < length:
    if citations[index] < 0 or citations[index] > 1000:
      return -1
    inc index

  var low = csize_t(0)
  var high = length
  if high > 1000:
    high = 1000
  while low < high:
    let middle = low + (high - low + 1) div 2
    var qualifying = csize_t(0)
    index = 0
    while index < length:
      if uint64(citations[index]) >= uint64(middle):
        inc qualifying
        if qualifying >= middle:
          break
      inc index
    if qualifying >= middle:
      low = middle
    else:
      high = middle - 1
  int64(low)
