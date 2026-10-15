## Plaintext-autokey cipher with a selectable output case dialect.
const MaxAutokeyLength = 1024

proc uppercaseLetter(value: int64): int64 =
  if value >= ord('a') and value <= ord('z'): value - 32 else: value

proc autokeyCipher*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "autokey_cipher".} =
  if input == nil or length < 6 or length > csize_t(4 + 2 * MaxAutokeyLength): return -1
  let mode = input[0]
  let dialect = input[1]
  let textLengthValue = input[2]
  let keyLengthValue = input[3]
  if (mode != 0 and mode != 1) or (dialect != 0 and dialect != 1) or textLengthValue < 1 or textLengthValue > MaxAutokeyLength or keyLengthValue < 1 or keyLengthValue > MaxAutokeyLength: return -1
  let textLength = int(textLengthValue)
  let keyLength = int(keyLengthValue)
  if int(length) != 4 + textLength + keyLength: return -1
  let keyStart = 4 + textLength
  for index in 0 ..< textLength:
    let value = input[4 + index]
    if not ((value >= ord('A') and value <= ord('Z')) or (value >= ord('a') and value <= ord('z'))): return -1
    if dialect == 1 and mode == 1 and value >= ord('A') and value <= ord('Z'): return -1
  for index in 0 ..< keyLength:
    let value = input[keyStart + index]
    if not ((value >= ord('A') and value <= ord('Z')) or (value >= ord('a') and value <= ord('z'))): return -1
  if outputCapacity < csize_t(textLength) or output == nil: return -2
  for index in 0 ..< textLength:
    let plain = uppercaseLetter(input[4 + index]) - ord('A')
    let keyValue = if index < keyLength: uppercaseLetter(input[keyStart + index])
      elif mode == 0: uppercaseLetter(input[4 + index - keyLength])
      else: uppercaseLetter(int64(output[index - keyLength]))
    let shift = keyValue - ord('A')
    let mapped = if mode == 0: (plain + shift) mod 26 else: (plain - shift + 26) mod 26
    let result = ord('A') + mapped + (if dialect == 1: 32 else: 0)
    output[index] = uint8(result)
  int64(textLength)
