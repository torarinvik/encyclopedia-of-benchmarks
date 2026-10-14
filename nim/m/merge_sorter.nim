const MaxValues = 1024

proc mergeRange(values, scratch: ptr UncheckedArray[int64], low, high: int) =
  if high - low <= 1:
    return
  let middle = low + (high - low) div 2
  mergeRange(values, scratch, low, middle)
  mergeRange(values, scratch, middle, high)
  var left = low
  var right = middle
  var output = low
  while left < middle and right < high:
    if values[left] <= values[right]:
      scratch[output] = values[left]
      inc left
    else:
      scratch[output] = values[right]
      inc right
    inc output
  while left < middle:
    scratch[output] = values[left]
    inc left
    inc output
  while right < high:
    scratch[output] = values[right]
    inc right
    inc output
  for index in low ..< high:
    values[index] = scratch[index]

proc merge_sorter*(values: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "merge_sorter".} =
  if length > csize_t(MaxValues): return
  var scratch: array[MaxValues, int64]
  mergeRange(values, cast[ptr UncheckedArray[int64]](addr scratch[0]), 0, int(length))
