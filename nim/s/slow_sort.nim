## SlowSort over an inclusive interval.
proc slowSortRange(values: ptr UncheckedArray[int64], first, last: int) =
  if first >= last: return
  let middle = first + (last - first) div 2
  slowSortRange(values, first, middle)
  slowSortRange(values, middle + 1, last)
  if values[last] < values[middle]: swap(values[last], values[middle])
  slowSortRange(values, first, last - 1)

proc slow_sort*(values: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "slow_sort".} =
  if length > 1: slowSortRange(values, 0, int(length) - 1)
