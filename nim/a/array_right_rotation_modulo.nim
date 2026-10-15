## Return a fresh right rotation using the shift modulo the input size.
const MaxArrayLength = 1024
const MaxInputLength = MaxArrayLength + 1
const MaxShift = 2147483647

proc array_right_rotation_modulo*(input: ptr UncheckedArray[int64], length: csize_t,
                          output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "array_right_rotation_modulo".} =
  if length < 1 or length > csize_t(MaxInputLength): return -1
  let shiftValue = input[0]
  if shiftValue < 0 or shiftValue > MaxShift: return -1
  let count = int(length) - 1
  var values: array[MaxArrayLength, int32]
  for index in 0 ..< count:
    let value = input[index + 1]
    if value < -2147483648'i64 or value > 2147483647'i64: return -1
    values[index] = int32(value)
  var shift = int(shiftValue)
  if count == 0: return -1
  shift = shift mod count
  let outputBytes = csize_t(count * 4)
  if outputCapacity < outputBytes: return -2
  for index in 0 ..< shift:
    let bits = cast[uint32](values[count - shift + index])
    for byte in 0 ..< 4:
      output[index * 4 + byte] = uint8((bits shr (byte * 8)) and 255)
  for index in 0 ..< count - shift:
    let bits = cast[uint32](values[index])
    let outputIndex = shift + index
    for byte in 0 ..< 4:
      output[outputIndex * 4 + byte] = uint8((bits shr (byte * 8)) and 255)
  int64(count)
