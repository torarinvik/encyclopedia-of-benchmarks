## Binary search the pair alignment around the unique value.
const MaxValues = 1025
const InvalidResult = -2147483649'i64

proc single_non_duplicate*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "single_non_duplicate".} =
  if length == 0 or length > csize_t(MaxValues) or length mod 2 == 0:
    return InvalidResult
  var left = 0
  var right = int(length) div 2
  while left < right:
    let middle = left + (right - left) div 2
    if values[middle * 2] == values[middle * 2 + 1]:
      left = middle + 1
    else:
      right = middle
  values[left * 2]
