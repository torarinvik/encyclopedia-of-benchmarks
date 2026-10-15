## Apply the case-preserving Atbash mapping to a 7-bit ASCII byte sequence.
proc atbashCipher*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "atbash_cipher".} =
  if length > 66: return -1
  for index in 0 ..< int(length):
    if input[index] < 0 or input[index] > 127: return -1
  if outputCapacity < length: return -2
  for index in 0 ..< int(length):
    let value = input[index]
    var mapped = value
    if value >= 65 and value <= 90:
      mapped = 155 - value
    elif value >= 97 and value <= 122:
      mapped = 219 - value
    output[index] = uint8(mapped)
  int64(length)
