## Rotate an array right by repeating a one-place shift.
const MaxArrayLength = 1024
const MaxInputLength = MaxArrayLength + 1
const MaxRotations = 1024

proc rotate_array*(input: ptr UncheckedArray[int64], length: csize_t,
                   output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "rotate_array".} =
  if length < 1 or length > csize_t(MaxInputLength): return -1
  let rotations = input[0]
  if rotations < 0 or rotations > MaxRotations: return -1
  let count = int(length) - 1
  var values: array[MaxArrayLength, int32]
  for index in 0 ..< count:
    let value = input[index + 1]
    if value < -2147483648'i64 or value > 2147483647'i64: return -1
    values[index] = int32(value)
  let outputBytes = csize_t(count * 4)
  if outputCapacity < outputBytes: return -2
  for _ in 0 ..< int(rotations):
    if count > 1:
      let last = values[count - 1]
      for index in countdown(count - 1, 1):
        values[index] = values[index - 1]
      values[0] = last
  for index in 0 ..< count:
    let bits = cast[uint32](values[index])
    for byte in 0 ..< 4:
      output[index * 4 + byte] = uint8((bits shr (byte * 8)) and 255)
  int64(count)
