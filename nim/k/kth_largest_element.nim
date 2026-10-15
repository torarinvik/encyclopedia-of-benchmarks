## Descending Lomuto quickselect with the final element as pivot.
const MaxLength = 512

proc kth_largest_element*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "kth_largest_element".} =
  if input == nil or length < 2 or length > MaxLength + 1: return -1
  let n = int(length) - 1
  if input[0] < 1 or input[0] > int64(n): return -1
  var values: array[MaxLength, int32]
  for index in 0 ..< n:
    let value = input[index + 1]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    values[index] = int32(value)
  let target = int(input[0]) - 1
  var lowIndex = 0
  var highIndex = n - 1
  while lowIndex <= highIndex:
    let pivot = values[highIndex]
    var boundary = lowIndex
    for scan in lowIndex ..< highIndex:
      if values[scan] >= pivot:
        swap(values[boundary], values[scan])
        inc boundary
    swap(values[boundary], values[highIndex])
    if boundary == target: return int64(values[boundary])
    if boundary > target: highIndex = boundary - 1
    else: lowIndex = boundary + 1
  -1
