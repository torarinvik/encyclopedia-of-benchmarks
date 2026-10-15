## Preserve the pinned Python source's plaintext-minus-repeating-key transform.
proc beaufort_cipher*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "beaufort_cipher".} =
  if input == nil or length < 3 or length > 2051: return -1
  let mode = input[0]
  let textLengthValue = input[1]
  let keyLengthValue = input[2]
  if (mode != 0 and mode != 1) or textLengthValue < 0 or textLengthValue > 1024 or
      keyLengthValue < 0 or keyLengthValue > 1024: return -1
  let textLength = int(textLengthValue)
  let keyLength = int(keyLengthValue)
  if int(length) != 3 + textLength + keyLength or
      (textLength == 0 and keyLength != 0) or
      (textLength > 0 and (keyLength == 0 or keyLength > textLength)): return -1
  let keyStart = 3 + textLength
  for index in 0 ..< textLength:
    let value = input[3 + index]
    if value != ord(' ').int64 and (value < ord('A') or value > ord('Z')): return -1
  for index in 0 ..< keyLength:
    if input[keyStart + index] < ord('A') or input[keyStart + index] > ord('Z'): return -1
  if outputCapacity < csize_t(textLength) or (textLength > 0 and output == nil): return -2
  var keyIndex = 0
  for index in 0 ..< textLength:
    let value = input[3 + index]
    if value == ord(' ').int64:
      output[index] = uint8(ord(' '))
      continue
    let letter = value - ord('A')
    let key = input[keyStart + keyIndex mod keyLength] - ord('A')
    let mapped = if mode == 0: (letter - key + 26) mod 26 else: (letter + key) mod 26
    output[index] = uint8(ord('A') + mapped)
    inc keyIndex
  int64(textLength)
