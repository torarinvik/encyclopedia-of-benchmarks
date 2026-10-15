## Return a fresh left rotation; nonpositive shifts keep order and positive shifts wrap.
const MaxArrayLength = 1024
const MaxInputLength = MaxArrayLength + 1

proc array_left_rotation_modulo*(input: ptr UncheckedArray[int64], length: csize_t,
                                 output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "array_left_rotation_modulo".} =
  if length < 1 or length > csize_t(MaxInputLength) or input.isNil: return -1
  let rotations = input[0]
  if rotations < -2147483648'i64 or rotations > 2147483647'i64: return -1
  let count = int(length) - 1
  var values: array[MaxArrayLength, int32]
  for index in 0 ..< count:
    let value = input[index + 1]
    if value < -2147483648'i64 or value > 2147483647'i64: return -1
    values[index] = int32(value)
  if count == 0: return 0
  let shift = if rotations > 0: int(rotations mod int64(count)) else: 0
  let outputBytes = csize_t(count * 4)
  if outputCapacity < outputBytes or output.isNil: return -2
  for index in shift ..< count:
    let bits = cast[uint32](values[index])
    let outputIndex = index - shift
    for byte in 0 ..< 4:
      output[outputIndex * 4 + byte] = uint8((bits shr (byte * 8)) and 255)
  for index in 0 ..< shift:
    let bits = cast[uint32](values[index])
    let outputIndex = count - shift + index
    for byte in 0 ..< 4:
      output[outputIndex * 4 + byte] = uint8((bits shr (byte * 8)) and 255)
  int64(count)

