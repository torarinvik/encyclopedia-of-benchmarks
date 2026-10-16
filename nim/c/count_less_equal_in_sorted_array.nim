proc count_less_equal_in_sorted_array*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "count_less_equal_in_sorted_array".} =
  if input.isNil or length < 1 or length > 513: return -1
  let key = input[0]
  if key < low(int32).int64 or key > high(int32).int64: return -1
  for index in 1 ..< int(length):
    let value = input[index]
    if value < low(int32).int64 or value > high(int32).int64: return -1
    if index > 1 and input[index - 1] > value: return -1

  var left = 1
  var right = int(length - 1)
  var count = 0
  while left <= right:
    let middle = left + (right - left) div 2
    if input[middle] > key: right = middle - 1
    else:
      count = middle
      left = middle + 1
  int64(count)
