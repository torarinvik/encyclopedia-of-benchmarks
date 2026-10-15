## Keyed Morse trigraph fractionation.
const
  MaxText = 256
  MaxKey = 64
  MorseCode: array[26, uint8] = [1'u8,8,10,4,0,2,6,0,0,7,5,4,3,2,7,6,13,2,0,1,1,1,3,9,11,12]
  MorseLength: array[26, int] = [2,4,4,3,1,4,3,4,2,4,3,4,2,2,3,4,4,3,3,1,3,4,3,4,4,4]
  MorseSymbols: array[3, uint8] = [uint8(ord('.')), uint8(ord('-')), uint8(ord('x'))]

proc makeKeyedAlphabet(input: ptr UncheckedArray[int64], keyStart, keyLength: int): array[26, uint8] =
  var keyed: array[26, uint8]
  var seen: array[26, bool]
  var count = 0
  for index in 0 ..< keyLength:
    var value = input[keyStart + index]
    if value >= ord('a') and value <= ord('z'): value -= 32
    let letter = int(value - ord('A'))
    if not seen[letter]:
      seen[letter] = true
      keyed[count] = uint8(value)
      inc count
  for letter in 0 ..< 26:
    if not seen[letter]:
      keyed[count] = uint8(ord('A') + letter)
      inc count
  keyed

proc morseLetter(morse: var array[1300, uint8], start, length: int): int =
  if length < 1 or length > 4: return -1
  var code = 0
  for offset in 0 ..< length: code = code * 2 + (if morse[start + offset] == ord('-').uint8: 1 else: 0)
  for letter in 0 ..< 26:
    if MorseLength[letter] == length and int(MorseCode[letter]) == code: return letter
  -1

proc fractionated_morse_cipher*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "fractionated_morse_cipher".} =
  if input == nil or length < 3 or length > csize_t(3 + MaxText + MaxKey): return -1
  let mode = input[0]
  let textValue = input[1]
  let keyValue = input[2]
  if (mode != 0 and mode != 1) or textValue < 0 or textValue > MaxText or keyValue < 0 or keyValue > MaxKey: return -1
  let textLength = int(textValue)
  let keyLength = int(keyValue)
  if int(length) != 3 + textLength + keyLength: return -1
  let keyStart = 3 + textLength
  for index in 0 ..< keyLength:
    let value = input[keyStart + index]
    if not ((value >= ord('A') and value <= ord('Z')) or (value >= ord('a') and value <= ord('z'))): return -1
  for index in 0 ..< textLength:
    let value = input[3 + index]
    if mode == 0:
      if value != ord(' ') and not ((value >= ord('A') and value <= ord('Z')) or (value >= ord('a') and value <= ord('z'))): return -1
    elif value < ord('A') or value > ord('Z'): return -1
  let keyed = makeKeyedAlphabet(input, keyStart, keyLength)
  var outputBytes: array[800, uint8]
  var resultLength = 0
  if mode == 0:
    var morse: array[1300, uint8]
    var morseLength = 0
    for index in 0 ..< textLength:
      if index != 0: morse[morseLength] = uint8(ord('x')); inc morseLength
      var value = input[3 + index]
      if value == ord(' '): continue
      if value >= ord('a') and value <= ord('z'): value -= 32
      let letter = int(value - ord('A'))
      for bit in 0 ..< MorseLength[letter]:
        let mask = 1 shl (MorseLength[letter] - bit - 1)
        morse[morseLength] = if (int(MorseCode[letter]) and mask) != 0: uint8(ord('-')) else: uint8(ord('.'))
        inc morseLength
    let padding = 3 - morseLength mod 3
    for _ in 0 ..< padding: morse[morseLength] = uint8(ord('x')); inc morseLength
    for start in countup(0, morseLength - 3, 3):
      var trigram = 0
      for offset in 0 ..< 3:
        let digit = if morse[start + offset] == ord('.').uint8: 0 elif morse[start + offset] == ord('-').uint8: 1 else: 2
        trigram = trigram * 3 + digit
      if trigram < 26: outputBytes[resultLength] = keyed[trigram]; inc resultLength
  else:
    var morse: array[1300, uint8]
    var morseLength = 0
    for index in 0 ..< textLength:
      var trigram = 0
      while trigram < 26 and int64(keyed[trigram]) != input[3 + index]: inc trigram
      if trigram == 26: return -1
      morse[morseLength] = MorseSymbols[trigram div 9]
      morse[morseLength + 1] = MorseSymbols[(trigram div 3) mod 3]
      morse[morseLength + 2] = MorseSymbols[trigram mod 3]
      morseLength += 3
    var segmentStart = 0
    for index in 0 .. morseLength:
      if index != morseLength and morse[index] != ord('x').uint8: continue
      let segmentLength = index - segmentStart
      if segmentLength == 0:
        outputBytes[resultLength] = uint8(ord(' ')); inc resultLength
      else:
        let letter = morseLetter(morse, segmentStart, segmentLength)
        if letter < 0: return -1
        outputBytes[resultLength] = uint8(ord('A') + letter); inc resultLength
      segmentStart = index + 1
    var first = 0
    while first < resultLength and outputBytes[first] == ord(' ').uint8: inc first
    while resultLength > first and outputBytes[resultLength - 1] == ord(' ').uint8: dec resultLength
    if first > 0:
      for index in first ..< resultLength: outputBytes[index - first] = outputBytes[index]
      resultLength -= first
  if outputCapacity < csize_t(resultLength) or (resultLength > 0 and output == nil): return -2
  for index in 0 ..< resultLength: output[index] = outputBytes[index]
  int64(resultLength)
