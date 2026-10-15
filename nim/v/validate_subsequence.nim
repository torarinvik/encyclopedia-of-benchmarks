const MAX_SEQUENCE_LENGTH = 4096

proc validate_subsequence*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "validate_subsequence".} =
  if values == nil or length < 2 or length > 8194:
    return -1
  if values[0] < 0 or values[0] > MAX_SEQUENCE_LENGTH or values[1] < 0 or values[1] > MAX_SEQUENCE_LENGTH:
    return -1
  let arrayLength = int(values[0])
  let sequenceLength = int(values[1])
  if int(length) != 2 + arrayLength + sequenceLength:
    return -1
  for i in 2 ..< int(length):
    if values[i] < int64(low(int32)) or values[i] > int64(high(int32)):
      return -1

  if arrayLength == 0:
    return 0
  if sequenceLength == 0:
    return 1
  let sequenceStart = 2 + arrayLength
  var arrayIndex = 0
  var sequenceIndex = 0
  while sequenceIndex < sequenceLength and arrayIndex < arrayLength:
    if values[sequenceStart + sequenceIndex] == values[2 + arrayIndex]:
      inc sequenceIndex
    inc arrayIndex
  return (if sequenceIndex == sequenceLength: 1 else: 0)
