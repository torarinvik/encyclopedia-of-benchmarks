## Remove every occurrence of target while preserving the surviving order.
const MaxLength = 4096

proc remove_element*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "remove_element".} =
  if length == 0 or length > csize_t(MaxLength) or input == nil: return -1
  let target = input[0]
  if target < int64(low(int32)) or target > int64(high(int32)): return -1
  var survivorCount = 0
  for index in 1 ..< int(length):
    let value = input[index]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    if value != target: inc survivorCount
  let outputBytes = survivorCount * 4
  if outputCapacity < csize_t(outputBytes) or (outputBytes != 0 and output == nil): return -2
  var written = 0
  for index in 1 ..< int(length):
    let value = input[index]
    if value != target:
      let bits = cast[uint32](int32(value))
      for byte in 0 ..< 4:
        output[written * 4 + byte] = uint8((bits shr (byte * 8)) and 0xff'u32)
      inc written
  if written != survivorCount: return -1
  int64(written)
