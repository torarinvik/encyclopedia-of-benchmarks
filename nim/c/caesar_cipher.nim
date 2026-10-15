## Apply a normalized Caesar shift to ASCII letters in a byte sequence.
proc caesarCipher*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "caesar_cipher".} =
  if length == 0 or length > 66: return -1
  let textLength = int(length - 1)
  for index in 0 ..< textLength:
    if input[index] < 0 or input[index] > 127: return -1
  if outputCapacity < csize_t(textLength): return -2

  var shift = input[textLength] mod 26
  if shift < 0: shift += 26
  for index in 0 ..< textLength:
    let value = input[index]
    var mapped = value
    if value >= 65 and value <= 90:
      mapped = 65 + (value - 65 + shift) mod 26
    elif value >= 97 and value <= 122:
      mapped = 97 + (value - 97 + shift) mod 26
    output[index] = uint8(mapped)
  int64(textLength)
