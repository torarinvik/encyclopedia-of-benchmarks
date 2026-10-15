## Rotate by reversing the whole array, then each side of the rotation.
const MaxArrayLength = 1024
const MaxInputLength = MaxArrayLength + 1

proc reverseRange(values: var array[MaxArrayLength, int32], startValue, endValue: int) =
  var start = startValue
  var ending = endValue
  while start < ending:
    dec ending
    if start >= ending: break
    swap(values[start], values[ending])
    inc start

proc rotate_array_reversal*(input: ptr UncheckedArray[int64], length: csize_t,
                            output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "rotate_array_reversal".} =
  if length < 1 or length > csize_t(MaxInputLength): return -1
  let steps = input[0]
  if steps < -2147483648'i64 or steps > 2147483647'i64: return -1
  let count = int(length) - 1
  var values: array[MaxArrayLength, int32]
  for index in 0 ..< count:
    let value = input[index + 1]
    if value < -2147483648'i64 or value > 2147483647'i64: return -1
    values[index] = int32(value)
  let outputBytes = csize_t(count * 4)
  if outputCapacity < outputBytes: return -2
  var shift = 0
  if count != 0:
    shift = int(steps mod int64(count))
    if shift < 0: shift += count
  reverseRange(values, 0, count)
  reverseRange(values, 0, shift)
  reverseRange(values, shift, count)
  for index in 0 ..< count:
    let bits = cast[uint32](values[index])
    for byte in 0 ..< 4:
      output[index * 4 + byte] = uint8((bits shr (byte * 8)) and 255)
  int64(count)
