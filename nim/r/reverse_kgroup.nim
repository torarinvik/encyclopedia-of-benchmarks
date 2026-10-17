const MaxInputLength = 258
const MaxListLength = 256

proc writeI32Le(output: ptr UncheckedArray[uint8], index: int, value: int32) =
  let bits = cast[uint32](value)
  let offset = index * 4
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u32)

proc reverse_kgroup*(input: ptr UncheckedArray[int32], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "reverse_kgroup".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let n = int(length - 1)
  let groupSizeValue = input[0]
  if groupSizeValue < 1 or groupSizeValue > int32(MaxListLength) or n > MaxListLength: return -1
  let groupSize = int(groupSizeValue)
  let outputBytes = n * 4
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  var start = 0
  while start + groupSize <= n:
    for offset in 0 ..< groupSize:
      writeI32Le(output, start + offset, input[1 + start + groupSize - 1 - offset])
    start += groupSize
  while start < n:
    writeI32Le(output, start, input[1 + start])
    inc start
  int64(outputBytes)
