## Sort up to ten bounded values and encode quartile statistics.
proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc quartile*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "quartile".} =
  if input == nil or length < 2 or length > 11 or input[0] < 1 or input[0] > 10: return -1
  let count = int(input[0])
  if int(length) != count + 1: return -1
  var values: array[10, int64]
  for index in 0 ..< count:
    if input[index + 1] < 0 or input[index + 1] > 99: return -1
    values[index] = input[index + 1]
  for i in 0 ..< count:
    for j in 0 ..< count:
      if values[i] < values[j]: swap(values[i], values[j])
  let q1 = values[count div 4]
  let q3 = values[(3 * count) div 4]
  let required = (count + 4) * 8
  if output == nil or outputCapacity < csize_t(required): return -2
  storeI64Le(output, 0, int64(count))
  for index in 0 ..< count: storeI64Le(output, 8 * (index + 1), values[index])
  storeI64Le(output, 8 * (count + 1), q1)
  storeI64Le(output, 8 * (count + 2), q3)
  storeI64Le(output, 8 * (count + 3), q3 - q1)
  int64(required)
