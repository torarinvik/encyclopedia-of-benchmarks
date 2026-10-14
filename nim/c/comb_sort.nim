## Comb sort with a rational 10/13 gap shrink factor.
proc shrinkGap(gap: csize_t): csize_t =
  (gap div 13) * 10 + ((gap mod 13) * 10) div 13

proc comb_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "comb_sort".} =
  if length < 2:
    return
  var gap = length
  var swapped = true
  while gap > 1 or swapped:
    gap = shrinkGap(gap)
    if gap < 1:
      gap = 1
    swapped = false
    var index = csize_t(0)
    while index < length - gap:
      if values[index] > values[index + gap]:
        let temporary = values[index]
        values[index] = values[index + gap]
        values[index + gap] = temporary
        swapped = true
      inc index
