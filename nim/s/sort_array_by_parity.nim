## Place evens first and fill the odd section from its end.
const MaxArrayLength = 5000

proc sort_array_by_parity*(input: ptr UncheckedArray[int64], length: csize_t,
                           output: ptr UncheckedArray[uint8],
                           outputCapacity: csize_t): int64
    {.cdecl, exportc: "sort_array_by_parity".} =
  if length > csize_t(MaxArrayLength) or (length != 0 and input.isNil): return -1
  for index in 0 ..< int(length):
    if input[index] < 0 or input[index] > 5000: return -1
  let outputBytes = csize_t(length * 4)
  if outputCapacity < outputBytes or (outputBytes != 0 and output.isNil): return -2

  var evenIndex = 0
  var oddIndex = int(length)
  for index in 0 ..< int(length):
    let value = uint32(input[index])
    var destination: int
    if (value and 1) == 0:
      destination = evenIndex
      inc evenIndex
    else:
      dec oddIndex
      destination = oddIndex
    for byte in 0 ..< 4:
      output[destination * 4 + byte] = uint8((value shr (byte * 8)) and 255)
  int64(length)
