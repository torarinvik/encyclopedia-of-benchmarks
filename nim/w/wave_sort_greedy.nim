## Greedily make even positions peaks: >= <= >= wave.
const MaxArrayLength = 4096

proc storeI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc wave_sort_greedy*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "wave_sort_greedy".} =
  if length > csize_t(MaxArrayLength) or (length != 0 and input == nil): return -1
  let count = int(length)
  var values: array[MaxArrayLength, int64]
  for index in 0 ..< count:
    let value = input[csize_t(index)]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    values[index] = value
  let byteCount = count * 4
  if outputCapacity < csize_t(byteCount) or (byteCount != 0 and output == nil): return -2
  var index = 0
  while index < count:
    if index > 0 and values[index] < values[index - 1]: swap(values[index], values[index - 1])
    if index + 1 < count and values[index] < values[index + 1]: swap(values[index], values[index + 1])
    index += 2
  for index in 0 ..< count: storeI32Le(output, index * 4, values[index])
  int64(count)
