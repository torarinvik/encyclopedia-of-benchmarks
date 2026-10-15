## Compact each value in an ascending array to its first occurrence.
const MaxLength = 4096

proc remove_duplicates_from_sorted_array*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "remove_duplicates_from_sorted_array".} =
  if length > csize_t(MaxLength) or (length != 0 and input == nil): return -1
  var uniqueCount = 0
  for index in 0 ..< int(length):
    let value = input[index]
    if value < int64(low(int32)) or value > int64(high(int32)) or
        (index > 0 and input[index - 1] > value): return -1
    if index == 0 or input[index - 1] != value: inc uniqueCount
  let outputBytes = uniqueCount * 4
  if outputCapacity < csize_t(outputBytes) or (outputBytes != 0 and output == nil): return -2
  var written = 0
  for index in 0 ..< int(length):
    let value = input[index]
    if index == 0 or input[index - 1] != value:
      let bits = cast[uint32](int32(value))
      for byte in 0 ..< 4:
        output[written * 4 + byte] = uint8((bits shr (byte * 8)) and 0xff'u32)
      inc written
  if written != uniqueCount: return -1
  int64(written)
