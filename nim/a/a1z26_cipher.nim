## Encode ASCII letters as their one-based alphabet positions.
proc a1z26Cipher*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "a1z26_cipher".} =
  if length > 66: return -1
  for index in 0 ..< int(length):
    let value = input[index]
    if not ((value >= 65 and value <= 90) or (value >= 97 and value <= 122)): return -1
  if outputCapacity < length: return -2
  for index in 0 ..< int(length):
    let value = input[index]
    output[index] = uint8(if value >= 97: value - 96 else: value - 64)
  int64(length)
