proc hill_cipher_mod26_java*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "hill_cipher_mod26_java".} =
  if input.isNil or length < 1 or length > 257: return -1
  if input[0] != 0 and input[0] != 1: return -1
  let key = if input[0] == 0: [3'i64, 3, 2, 5] else: [15'i64, 17, 20, 9]
  var text: array[256, uint8]; var textLength = 0
  for i in 1 ..< int(length):
    if input[i] < 0 or input[i] > 127: return -1
    var c = uint8(input[i])
    if c >= uint8('a') and c <= uint8('z'): c = c - uint8('a') + uint8('A')
    if c >= uint8('A') and c <= uint8('Z'): text[textLength] = c; inc textLength
  if textLength mod 2 == 1: text[textLength] = uint8('X'); inc textLength
  if csize_t(textLength) > capacity or (textLength > 0 and output.isNil): return -2
  if textLength == 0: return 0
  for i in countup(0, textLength - 1, 2):
    let a = int64(text[i] - uint8('A')); let b = int64(text[i+1] - uint8('A'))
    output[i] = uint8(int64('A') + (key[0]*a + key[1]*b) mod 26)
    output[i+1] = uint8(int64('A') + (key[2]*a + key[3]*b) mod 26)
  int64(textLength)
