## Divide-and-conquer maximum nonempty contiguous-subarray sum.
proc max_subarray_range(values: ptr UncheckedArray[int64], start, finish: csize_t): int64 =
  if finish - start == 1:
    return values[start]
  let middle = start + (finish - start) div 2
  let left_best = max_subarray_range(values, start, middle)
  let right_best = max_subarray_range(values, middle, finish)
  var running = values[middle - 1]
  var left_suffix = running
  var index = middle - 1
  while index > start:
    dec index
    running += values[index]
    if running > left_suffix:
      left_suffix = running
  running = values[middle]
  var right_prefix = running
  index = middle + 1
  while index < finish:
    running += values[index]
    if running > right_prefix:
      right_prefix = running
    inc index
  let crossing = left_suffix + right_prefix
  max(max(left_best, right_best), crossing)

proc max_subarray*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "max_subarray".} =
  if length == 0 or length > 1024:
    return -1
  for index in 0 ..< length:
    if values[index] < -2147483648'i64 or values[index] > 2147483647'i64:
      return -1
  max_subarray_range(values, 0, length)
