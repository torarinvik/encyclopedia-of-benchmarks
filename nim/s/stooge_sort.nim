## Stooge sort on half-open ranges.
proc stoogeSortRange(values: ptr UncheckedArray[int64], low, high: csize_t) =
  let length = high - low
  if length < 2:
    return
  if values[low] > values[high - 1]:
    swap(values[low], values[high - 1])
  if length > 2:
    let third = length div 3
    stoogeSortRange(values, low, high - third)
    stoogeSortRange(values, low + third, high)
    stoogeSortRange(values, low, high - third)

proc stooge_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "stooge_sort".} =
  if length > 1:
    stoogeSortRange(values, 0, length)
