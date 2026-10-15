## Return each box's movement count as a 16-bit little-endian value.
proc minimum_operations_to_move_all_balls*(boxes: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "minimum_operations_to_move_all_balls".} =
  if length > 256 or (length > 0 and boxes.isNil): return -1
  var rightOnes = 0'i64
  var rightDistance = 0'i64
  for index in 0 ..< int(length):
    let value = boxes[index]
    if value != 0 and value != 1: return -1
    if value == 1:
      inc rightOnes
      rightDistance += int64(index)
  let requiredCapacity = length * 2
  if outputCapacity < requiredCapacity: return -2
  var leftOnes = 0'i64
  var leftDistance = 0'i64
  for index in 0 ..< int(length):
    if boxes[index] == 1:
      dec rightOnes
      inc leftOnes
    let distance = leftDistance + rightDistance
    output[index * 2] = uint8(distance mod 256)
    output[index * 2 + 1] = uint8(distance div 256)
    rightDistance -= rightOnes
    leftDistance += leftOnes
  int64(length)
