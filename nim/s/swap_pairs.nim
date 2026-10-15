## Swap adjacent node values in a bounded array representation of a list.
const MaxLength = 1024

proc swap_pairs*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "swap_pairs".} =
  if length > csize_t(MaxLength) or (length != 0 and input == nil): return -1
  for index in 0 ..< int(length):
    if input[index] < int64(low(int32)) or input[index] > int64(high(int32)): return -1
  let outputBytes = int(length) * 4
  if outputCapacity < csize_t(outputBytes) or (outputBytes != 0 and output == nil): return -2

  for index in 0 ..< int(length):
    let pairStart = (index div 2) * 2
    let sourceIndex = if index mod 2 == 0 and pairStart + 1 < int(length): pairStart + 1 else: pairStart
    let bits = cast[uint32](int32(input[sourceIndex]))
    for byte in 0 ..< 4:
      output[index * 4 + byte] = uint8((bits shr (byte * 8)) and 0xff'u32)
  int64(length)
