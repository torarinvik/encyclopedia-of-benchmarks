## Encode ASCII letters and digits as space-separated International Morse.
proc morseLetterIndex(value: int64): int64 =
  if value >= 65 and value <= 90: return value - 65
  if value >= 97 and value <= 122: return value - 97
  if value >= 48 and value <= 57: return 26 + value - 48
  -1

proc morseWord(index: int): int64 =
  if index == 0: return 514
  if index == 1: return 1031
  if index == 2: return 1029
  if index == 3: return 771
  if index == 4: return 257
  if index == 5: return 1037
  if index == 6: return 769
  if index == 7: return 1039
  if index == 8: return 515
  if index == 9: return 1032
  if index == 10: return 770
  if index == 11: return 1035
  if index == 12: return 512
  if index == 13: return 513
  if index == 14: return 768
  if index == 15: return 1033
  if index == 16: return 1026
  if index == 17: return 773
  if index == 18: return 775
  if index == 19: return 256
  if index == 20: return 774
  if index == 21: return 1038
  if index == 22: return 772
  if index == 23: return 1030
  if index == 24: return 1028
  if index == 25: return 1027
  if index == 26: return 1280
  if index == 27: return 1296
  if index == 28: return 1304
  if index == 29: return 1308
  if index == 30: return 1310
  if index == 31: return 1311
  if index == 32: return 1295
  if index == 33: return 1287
  if index == 34: return 1283
  if index == 35: return 1281
  0

proc morseCode*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "morse_code".} =
  if length > 682: return -1
  var required = csize_t(0)
  for index in 0 ..< int(length):
    let letter = morseLetterIndex(input[index])
    if letter < 0: return -1
    let word = morseWord(int(letter))
    required += csize_t((word div 256) mod 8)
    if index != 0: inc required
  if outputCapacity < required: return -2
  var written = csize_t(0)
  for index in 0 ..< int(length):
    if index != 0:
      output[written] = 32
      inc written
    let word = morseWord(int(morseLetterIndex(input[index])))
    let codeLength = int((word div 256) mod 8)
    let mask = word mod 32
    for position in 0 ..< codeLength:
      let shift = codeLength - position - 1
      output[written] = if ((mask shr shift) and 1) != 0: 46'u8 else: 45'u8
      inc written
  int64(written)
