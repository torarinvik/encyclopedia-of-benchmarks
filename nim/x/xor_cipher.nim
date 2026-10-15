## XOR each input byte with a repeating key byte sequence.
proc xorCipher*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "xor_cipher".} =
  if length < 3 or length > 66 or input[0] < 0 or input[0] > 63 or
      input[1] < 1 or input[1] > 63: return -1
  let textLength = int(input[0])
  let keyLength = int(input[1])
  if int(length) != 2 + textLength + keyLength: return -1
  for index in 0 ..< textLength + keyLength:
    if input[2 + index] < 0 or input[2 + index] > 255: return -1
  if outputCapacity < csize_t(textLength): return -2
  for index in 0 ..< textLength:
    output[index] = uint8(input[2 + index] xor input[2 + textLength + index mod keyLength])
  int64(textLength)
