## Decode one-based alphabet positions as lowercase ASCII letters.
proc a1z26Decipher*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "a1z26_decipher".} =
  if length > 66: return -1
  for index in 0 ..< int(length):
    if input[index] < 1 or input[index] > 26: return -1
  if outputCapacity < length: return -2
  for index in 0 ..< int(length): output[index] = uint8(96 + input[index])
  int64(length)
