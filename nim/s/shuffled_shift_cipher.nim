const
  MaxPasscodeLength = 20
  MaxTextLength = 256
  MaxParseableInputLength = 279
  AlphabetLength = 97

proc isAsciiAlphanumeric(value: int64): bool =
  (value >= 48 and value <= 57) or (value >= 65 and value <= 90) or (value >= 97 and value <= 122)

proc shuffled_shift_cipher*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "shuffled_shift_cipher".} =
  if input == nil or inputLength < 2 or inputLength > MaxParseableInputLength.csize_t:
    return -1
  let passLengthValue = input[0]
  let textLengthValue = input[1]
  if passLengthValue < 1 or passLengthValue > MaxPasscodeLength.int64 or
      textLengthValue < 0 or textLengthValue > MaxTextLength.int64:
    return -1
  let passLength = int(passLengthValue)
  let textLength = int(textLengthValue)
  if inputLength != (2 + passLength + textLength).csize_t:
    return -1

  var passcode: array[MaxPasscodeLength, uint8]
  for index in 0 ..< passLength:
    let value = input[index + 2]
    if not isAsciiAlphanumeric(value):
      return -1
    passcode[index] = uint8(value)
  let textStart = 2 + passLength
  var plaintext: array[MaxTextLength, uint8]
  for index in 0 ..< textLength:
    let value = input[textStart + index]
    if not ((value >= 32 and value <= 126) or value == 9 or value == 10):
      return -1
    plaintext[index] = uint8(value)

  if output == nil or outputCapacity < textLength.csize_t:
    return -2

  var breakpoints: array[128, bool]
  var shiftSum = 0'i64
  for index in 0 ..< passLength:
    let byte = passcode[index]
    breakpoints[int(byte)] = true
    if index mod 2 == 0:
      shiftSum += int64(byte)
    else:
      shiftSum -= int64(byte)
  let shift = if shiftSum > 0: int(shiftSum) else: passLength

  var alphabet: array[AlphabetLength, uint8]
  var alphabetLength = 0
  for value in uint8(ord('a')) .. uint8(ord('z')):
    alphabet[alphabetLength] = value
    inc alphabetLength
  for value in uint8(ord('A')) .. uint8(ord('Z')):
    alphabet[alphabetLength] = value
    inc alphabetLength
  for value in uint8(ord('0')) .. uint8(ord('9')):
    alphabet[alphabetLength] = value
    inc alphabetLength
  for value in uint8(ord('!')) .. uint8(ord('~')):
    if not isAsciiAlphanumeric(int64(value)):
      alphabet[alphabetLength] = value
      inc alphabetLength
  alphabet[alphabetLength] = uint8(ord(' ')); inc alphabetLength
  alphabet[alphabetLength] = 9; inc alphabetLength
  alphabet[alphabetLength] = 10; inc alphabetLength

  var key: array[AlphabetLength, uint8]
  var keyLength = 0
  var segment: array[AlphabetLength, uint8]
  var segmentLength = 0
  for index in 0 ..< alphabetLength:
    let byte = alphabet[index]
    segment[segmentLength] = byte
    inc segmentLength
    if breakpoints[int(byte)] or index + 1 == alphabetLength:
      while segmentLength > 0:
        dec segmentLength
        key[keyLength] = segment[segmentLength]
        inc keyLength

  for index in 0 ..< textLength:
    let byte = plaintext[index]
    var keyIndex = 0
    while keyIndex < keyLength and key[keyIndex] != byte:
      inc keyIndex
    let shifted = (keyIndex + shift) mod AlphabetLength
    output[index] = key[shifted]
  return int64(textLength)
