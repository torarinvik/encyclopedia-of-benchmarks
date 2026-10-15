## Stable nonzero compaction followed by a zero-fill pass.
const MaxLength = 4096

proc writeI32Le(output: ptr UncheckedArray[uint8], index: csize_t, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0 ..< 4:
    output[index * 4 + csize_t(byte)] = uint8((bits shr (byte * 8)) and 0xff'u32)

proc move_zeroes*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "move_zeroes".} =
  if length > csize_t(MaxLength) or (length != 0 and input == nil): return -1
  for index in 0 ..< int(length):
    if input[index] < int64(low(int32)) or input[index] > int64(high(int32)): return -1
  let outputBytes = length * 4
  if outputCapacity < outputBytes or (outputBytes != 0 and output == nil): return -2
  var writeIndex: csize_t = 0
  for index in 0 ..< int(length):
    let value = input[index]
    if value != 0:
      writeI32Le(output, writeIndex, value)
      inc writeIndex
  while writeIndex < length:
    writeI32Le(output, writeIndex, 0)
    inc writeIndex
  int64(length)
