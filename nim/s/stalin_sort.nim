## Keep each value that is not smaller than the last retained value.
const MaxInputLength = 128

proc storeI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u32)

proc stalin_sort*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "stalin_sort".} =
  if length > csize_t(MaxInputLength) or (length != 0 and values == nil): return -1
  let count = int(length)
  for index in 0 ..< count:
    let value = values[csize_t(index)]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1

  var kept = 0
  var last = 0'i64
  for index in 0 ..< count:
    let value = values[csize_t(index)]
    if kept == 0 or value >= last:
      inc kept
      last = value
  let outputBytes = kept * 4
  if output == nil or outputCapacity < csize_t(outputBytes): return -2

  var outputIndex = 0
  last = 0
  for index in 0 ..< count:
    let value = values[csize_t(index)]
    if outputIndex == 0 or value >= last:
      storeI32Le(output, outputIndex * 4, value)
      inc outputIndex
      last = value
  int64(outputBytes)
