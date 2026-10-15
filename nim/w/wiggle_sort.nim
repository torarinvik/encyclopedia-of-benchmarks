## One-pass alternating local swaps: <= >= <= wave.
const MaxArrayLength = 4096

proc storeI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc wiggle_sort*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "wiggle_sort".} =
  if length > csize_t(MaxArrayLength) or (length != 0 and input == nil): return -1
  let count = int(length)
  var values: array[MaxArrayLength, int64]
  for index in 0 ..< count:
    let value = input[csize_t(index)]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    values[index] = value
  let byteCount = count * 4
  if outputCapacity < csize_t(byteCount) or (byteCount != 0 and output == nil): return -2
  var index = 1
  while index < count:
    if (index mod 2 == 1 and values[index - 1] > values[index]) or (index mod 2 == 0 and values[index - 1] < values[index]):
      swap(values[index], values[index - 1])
    index += 1
  for index in 0 ..< count: storeI32Le(output, index * 4, values[index])
  int64(count)
