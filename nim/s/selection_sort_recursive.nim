## Recursive selection sort for the shared signed 64-bit benchmark contract.
proc minimum_index(values: ptr UncheckedArray[int64], start, end: csize_t): csize_t =
  if start + 1 >= end:
    return start
  let minimum = minimum_index(values, start + 1, end)
  if values[start] < values[minimum]:
    return start
  return minimum

proc selection_sort_range(values: ptr UncheckedArray[int64], start, length: csize_t) =
  if start + 1 >= length:
    return
  let minimum = minimum_index(values, start, length)
  if minimum != start:
    let temporary = values[start]
    values[start] = values[minimum]
    values[minimum] = temporary
  selection_sort_range(values, start + 1, length)

proc selection_sort_recursive*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "selection_sort_recursive".} =
  selection_sort_range(values, 0, length)
