## Reciprocal Porta tableau cipher.
proc porta_cipher*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "porta_cipher".} =
  if input == nil or length < 3 or length > 1091: return -1
  let mode = input[0]
  let textValue = input[1]
  let keyValue = input[2]
  if (mode != 0 and mode != 1) or textValue < 0 or textValue > 1024 or keyValue < 0 or keyValue > 64: return -1
  let textLength = int(textValue)
  let keyLength = int(keyValue)
  if int(length) != 3 + textLength + keyLength or (textLength > 0 and keyLength == 0): return -1
  let keyStart = 3 + textLength
  for index in 3 ..< int(length):
    let value = input[index]
    if not ((value >= ord('A') and value <= ord('Z')) or (value >= ord('a') and value <= ord('z'))): return -1
  if outputCapacity < csize_t(textLength) or (textLength > 0 and output == nil): return -2
  for index in 0 ..< textLength:
    var letter = input[3 + index]
    var keyLetter = input[keyStart + index mod keyLength]
    if letter >= ord('a'): letter -= 32
    if keyLetter >= ord('a'): keyLetter -= 32
    let letterIndex = letter - ord('A')
    let group = (keyLetter - ord('A')) div 2
    let mapped = if letterIndex < 13: 13 + (letterIndex + 13 - group) mod 13 else: (letterIndex - 13 + group) mod 13
    output[index] = uint8(ord('A') + mapped)
  int64(textLength)
