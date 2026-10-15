## Return the lower-bound position in a strictly increasing signed 32-bit array.
proc search_insert_position*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "search_insert_position".} =
  if length < 1 or length > 257 or input.isNil: return -1
  let target = input[0]
  if target < low(int32).int64 or target > high(int32).int64: return -1
  for index in 1 ..< int(length):
    if input[index] < low(int32).int64 or input[index] > high(int32).int64: return -1
    if index > 1 and input[index - 1] >= input[index]: return -1
  var lowIndex = 0
  var highIndex = int(length - 1)
  while lowIndex < highIndex:
    let middle = lowIndex + (highIndex - lowIndex) div 2
    if input[middle + 1] < target: lowIndex = middle + 1
    else: highIndex = middle
  int64(lowIndex)
