## Square a sorted array and emit the results in ascending order.
const MaxArrayLength = 10000

proc squares_of_a_sorted_array*(input: ptr UncheckedArray[int64], length: csize_t,
                                output: ptr UncheckedArray[uint8],
                                outputCapacity: csize_t): int64
    {.cdecl, exportc: "squares_of_a_sorted_array".} =
  if length > csize_t(MaxArrayLength) or (length != 0 and input.isNil): return -1
  for index in 0 ..< int(length):
    if input[index] < -10000 or input[index] > 10000: return -1
    if index > 0 and input[index - 1] > input[index]: return -1
  let outputBytes = csize_t(length * 8)
  if outputCapacity < outputBytes or (outputBytes != 0 and output.isNil): return -2

  var left = 0
  var right = int(length)
  var destination = int(length)
  while destination > 0:
    dec destination
    let leftValue = input[left]
    let rightValue = input[right - 1]
    let leftMagnitude = if leftValue < 0: -leftValue else: leftValue
    let rightMagnitude = if rightValue < 0: -rightValue else: rightValue
    var value: int64
    if leftMagnitude > rightMagnitude:
      value = leftValue
      inc left
    else:
      value = rightValue
      dec right
    let square = uint64(value * value)
    for byte in 0 ..< 8:
      output[destination * 8 + byte] = uint8((square shr (byte * 8)) and 255)
  int64(length)
