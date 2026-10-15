## Encrypt ASCII text with a repeating, case-insensitive Vigenere key.
proc vigenereCipher*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "vigenere_cipher".} =
  if length < 2 or length > 66: return -1
  var separator = 0
  while separator < int(length) and input[separator] != 0: inc separator
  if separator == int(length) or separator + 1 == int(length): return -1
  let keyLength = int(length) - separator - 1
  for index in 0 ..< separator:
    if input[index] < 1 or input[index] > 127: return -1
  for index in 0 ..< keyLength:
    let value = input[separator + 1 + index]
    if not ((value >= 65 and value <= 90) or (value >= 97 and value <= 122)): return -1
  if outputCapacity < csize_t(separator): return -2

  var keyIndex = 0
  for index in 0 ..< separator:
    let value = input[index]
    var mapped = value
    if value >= 65 and value <= 90:
      var keyValue = input[separator + 1 + keyIndex]
      if keyValue >= 97: keyValue -= 32
      mapped = 65 + (value - 65 + keyValue - 65) mod 26
      keyIndex = (keyIndex + 1) mod keyLength
    elif value >= 97 and value <= 122:
      var keyValue = input[separator + 1 + keyIndex]
      if keyValue <= 90: keyValue += 32
      mapped = 97 + (value - 97 + keyValue - 97) mod 26
      keyIndex = (keyIndex + 1) mod keyLength
    output[index] = uint8(mapped)
  int64(separator)
