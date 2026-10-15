## Alphabetic Vernam cipher with a repeating key and modulo-26 arithmetic.
const MaxVernamLength = 1024

proc vernamCipher*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "vernam_cipher".} =
  if input == nil or length < 3 or length > csize_t(3 + 2 * MaxVernamLength): return -1
  let mode = input[0]
  let textLengthValue = input[1]
  let keyLengthValue = input[2]
  if (mode != 0 and mode != 1) or textLengthValue < 0 or textLengthValue > MaxVernamLength or keyLengthValue < 1 or keyLengthValue > MaxVernamLength: return -1
  let textLength = int(textLengthValue)
  let keyLength = int(keyLengthValue)
  if int(length) != 3 + textLength + keyLength: return -1
  let keyStart = 3 + textLength
  for index in 0 ..< textLength:
    if input[3 + index] < ord('A') or input[3 + index] > ord('Z'): return -1
  for index in 0 ..< keyLength:
    if input[keyStart + index] < ord('A') or input[keyStart + index] > ord('Z'): return -1
  if outputCapacity < csize_t(textLength): return -2

  for index in 0 ..< textLength:
    let textValue = input[3 + index] - ord('A')
    let keyValue = input[keyStart + index mod keyLength] - ord('A')
    let mapped = if mode == 0: (textValue + keyValue) mod 26 else: (textValue - keyValue + 26) mod 26
    output[index] = uint8(ord('A') + mapped)
  int64(textLength)
