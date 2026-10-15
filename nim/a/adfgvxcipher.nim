const MaxPlaintext = 256
const MaxCiphertext = 512
const MaxKey = 16
const MaxRows = 512
const Labels = "ADFGVX"
const Square = "NA1C3H8TB2OME5WRPD4F6G7I9J0KLQSUVXYZ"

proc polybiusCell(value: int64): int =
  for cell in 0 ..< 36:
    if ord(Square[cell]) == int(value): return cell
  -1

proc labelIndex(value: int64): int =
  for index, label in Labels:
    if ord(label) == int(value): return index
  -1

proc adfgvxcipher*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "adfgvxcipher".} =
  if input == nil or length < 3: return -1
  let mode = input[0]
  let textLengthValue = input[1]
  let keyLengthValue = input[2]
  if (mode != 0 and mode != 1) or textLengthValue < 0 or keyLengthValue < 1 or keyLengthValue > MaxKey: return -1
  let textLength = int(textLengthValue)
  let keyLength = int(keyLengthValue)
  if (mode == 0 and textLength > MaxPlaintext) or (mode == 1 and textLength > MaxCiphertext) or
      int(length) != 3 + textLength + keyLength: return -1
  for index in 0 ..< textLength:
    if input[3 + index] < 0 or input[3 + index] > 127: return -1
    if mode == 1 and labelIndex(input[3 + index]) < 0: return -1
  if mode == 1 and textLength mod 2 != 0: return -1

  let keyStart = 3 + textLength
  for index in 0 ..< keyLength:
    if input[keyStart + index] < 65 or input[keyStart + index] > 90: return -1
    for previous in 0 ..< index:
      if input[keyStart + index] == input[keyStart + previous]: return -1
  var order: array[MaxKey, int]
  for index in 0 ..< keyLength: order[index] = index
  for index in 1 ..< keyLength:
    let current = order[index]
    var position = index
    while position > 0 and input[keyStart + order[position - 1]] > input[keyStart + current]:
      order[position] = order[position - 1]
      dec position
    order[position] = current

  var resultBytes: array[MaxCiphertext, uint8]
  var resultLength = 0
  if mode == 0:
    var fractionated: array[MaxCiphertext, uint8]
    var fractionatedLength = 0
    for index in 0 ..< textLength:
      var value = int(input[3 + index])
      if value >= 97 and value <= 122: value -= 32
      if not ((value >= 65 and value <= 90) or (value >= 48 and value <= 57)): continue
      let cell = polybiusCell(int64(value))
      if cell < 0: return -1
      fractionated[fractionatedLength] = uint8(ord(Labels[cell div 6]))
      fractionated[fractionatedLength + 1] = uint8(ord(Labels[cell mod 6]))
      fractionatedLength += 2
    let rows = (fractionatedLength + keyLength - 1) div keyLength
    var table: array[MaxRows * MaxKey, uint8]
    for row in 0 ..< rows:
      for column in 0 ..< keyLength: table[row * MaxKey + column] = uint8(ord('_'))
    for index in 0 ..< fractionatedLength: table[(index div keyLength) * MaxKey + index mod keyLength] = fractionated[index]
    for orderIndex in 0 ..< keyLength:
      let column = order[orderIndex]
      for row in 0 ..< rows:
        let value = table[row * MaxKey + column]
        if value != uint8(ord('_')):
          resultBytes[resultLength] = value
          inc resultLength
  else:
    let rows = (textLength + keyLength - 1) div keyLength
    var table: array[MaxRows * MaxKey, uint8]
    var sourceIndex = 0
    for orderIndex in 0 ..< keyLength:
      let column = order[orderIndex]
      for row in 0 ..< rows:
        if sourceIndex < textLength:
          table[row * MaxKey + column] = uint8(input[3 + sourceIndex])
          inc sourceIndex
        else:
          table[row * MaxKey + column] = uint8(ord('_'))
    var fractionated: array[MaxCiphertext, uint8]
    var fractionatedLength = 0
    for row in 0 ..< rows:
      for column in 0 ..< keyLength:
        let value = table[row * MaxKey + column]
        if value != uint8(ord('_')):
          fractionated[fractionatedLength] = value
          inc fractionatedLength
    for index in 0 ..< fractionatedLength div 2:
      let row = labelIndex(int64(fractionated[index * 2]))
      let column = labelIndex(int64(fractionated[index * 2 + 1]))
      if row < 0 or column < 0: return -1
      resultBytes[resultLength] = uint8(ord(Square[row * 6 + column]))
      inc resultLength

  if outputCapacity < csize_t(resultLength) or (resultLength > 0 and output == nil): return -2
  for index in 0 ..< resultLength: output[index] = resultBytes[index]
  int64(resultLength)
