## Intersect three strictly increasing arrays and emit ascending signed i64 values.
const ArrayCount = 3
const MaxArrayLength = 64
const BytesPerValue = 8

proc storeI64Le(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< BytesPerValue:
    output[position + byte] = uint8((bits shr (byte * 8)) and 255)

proc sorted_arrays_intersection*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "sorted_arrays_intersection".} =
  if input == nil or length < ArrayCount or length > csize_t(ArrayCount * (MaxArrayLength + 1)): return -1
  var starts: array[ArrayCount, int]
  var sizes: array[ArrayCount, int]
  var position = 0
  for arrayIndex in 0 ..< ArrayCount:
    if position >= int(length) or input[position] < 0 or input[position] > MaxArrayLength: return -1
    let size = int(input[position]); inc position
    if size > int(length) - position: return -1
    starts[arrayIndex] = position
    sizes[arrayIndex] = size
    for index in 1 ..< size:
      if input[position + index - 1] >= input[position + index]: return -1
    position += size
  if position != int(length): return -1
  let maximumResult = min(sizes[0], min(sizes[1], sizes[2]))
  if int(outputCapacity) < maximumResult * BytesPerValue or (maximumResult > 0 and output == nil): return -2

  var cursor: array[ArrayCount, int]
  var resultCount = 0
  while cursor[0] < sizes[0] and cursor[1] < sizes[1] and cursor[2] < sizes[2]:
    let first = input[starts[0] + cursor[0]]
    let second = input[starts[1] + cursor[1]]
    let third = input[starts[2] + cursor[2]]
    if first == second and first == third:
      storeI64Le(output, resultCount * BytesPerValue, first)
      inc resultCount
      inc cursor[0]; inc cursor[1]; inc cursor[2]
    elif first < second:
      inc cursor[0]
    elif second < third:
      inc cursor[1]
    else:
      inc cursor[2]
  int64(resultCount)
