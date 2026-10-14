## Portable bitonic sorting network for power-of-two lengths.
proc bitonicCompare(values: ptr UncheckedArray[int64], left, right: csize_t, ascending: bool) =
  if (ascending and values[left] > values[right]) or (not ascending and values[left] < values[right]):
    swap(values[left], values[right])

proc bitonicMerge(values: ptr UncheckedArray[int64], low, length: csize_t, ascending: bool) =
  if length < 2:
    return
  let half = length div 2
  for index in low ..< low + half:
    bitonicCompare(values, index, index + half, ascending)
  bitonicMerge(values, low, half, ascending)
  bitonicMerge(values, low + half, half, ascending)

proc bitonicSortRange(values: ptr UncheckedArray[int64], low, length: csize_t, ascending: bool) =
  if length < 2:
    return
  let half = length div 2
  bitonicSortRange(values, low, half, true)
  bitonicSortRange(values, low + half, half, false)
  bitonicMerge(values, low, length, ascending)

proc bitonic_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "bitonic_sort".} =
  if length < 2:
    return
  bitonicSortRange(values, 0, length, true)
