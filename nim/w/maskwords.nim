const
  MaxTextBytes = 512
  MaxMaskBytes = 16
  MaxParseableInputLength = 531
  MaxOutputBytes = 1447
  Words = ["birds", "market", "street"]
  NormalizedVariants = ["birds", "BIRDS", "Birds", "market", "MARKET",
                        "Market", "street", "STREET", "Street"]

proc isWord(value: uint8): bool =
  (value >= uint8(ord('A')) and value <= uint8(ord('Z'))) or
  (value >= uint8(ord('a')) and value <= uint8(ord('z'))) or
  (value >= uint8(ord('0')) and value <= uint8(ord('9'))) or value == uint8(ord('_'))

proc equalsWord(text: openArray[uint8], start, finish: int, word: string): bool =
  if finish - start != word.len: return false
  for i in 0 ..< word.len:
    if text[start + i] != uint8(ord(word[i])): return false
  true

proc isNormalizedTarget(text: openArray[uint8], start, finish: int): bool =
  for variant in NormalizedVariants:
    if equalsWord(text, start, finish, variant): return true
  false

proc matchLength(text: openArray[uint8], start, finish, position: int): int =
  for word in Words:
    let wordLength = word.len
    if position + wordLength <= finish and equalsWord(text, position, position + wordLength, word) and
        (position == start or not isWord(text[position - 1])) and
        (position + wordLength == finish or not isWord(text[position + wordLength])):
      return wordLength
  0

proc appendToken(text: openArray[uint8], start, finish: int, mask: openArray[uint8],
                 maskLength: int, output: var array[MaxOutputBytes, uint8],
                 writtenValue: int): int =
  var written = writtenValue
  if isNormalizedTarget(text, start, finish):
    for i in 0 ..< maskLength:
      output[written] = mask[i]
      inc written
    return written
  var position = start
  while position < finish:
    let matched = matchLength(text, start, finish, position)
    if matched != 0:
      for i in 0 ..< maskLength:
        output[written] = mask[i]
        inc written
      position += matched
    else:
      if text[position] != uint8(ord('\n')):
        output[written] = text[position]
        inc written
      inc position
  written

proc maskwords*(values: ptr UncheckedArray[int64], length: csize_t,
                output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if values == nil or length < csize_t(2) or length > csize_t(MaxParseableInputLength): return -1
  if values[0] < 0 or values[0] > int64(MaxTextBytes): return -1
  let textLength = int(values[0])
  let maskLengthIndex = 1 + textLength
  if maskLengthIndex >= int(length) or values[maskLengthIndex] < 0 or
      values[maskLengthIndex] > int64(MaxMaskBytes): return -1
  let maskLength = int(values[maskLengthIndex])
  if int(length) != maskLengthIndex + 1 + maskLength: return -1

  var textStorage: array[MaxTextBytes, uint8]
  var maskStorage: array[MaxMaskBytes, uint8]
  for i in 0 ..< textLength:
    let value = values[1 + i]
    if value < 1 or value > 127: return -1
    textStorage[i] = uint8(value)
  for i in 0 ..< maskLength:
    let value = values[maskLengthIndex + 1 + i]
    if value < 32 or value > 126 or value == 92: return -1
    maskStorage[i] = uint8(value)

  var scratch: array[MaxOutputBytes, uint8]
  var written = 0
  var start = 0
  var haveToken = false
  for i in 0 ..< textLength:
    if textStorage[i] == uint8(ord(' ')):
      if haveToken:
        scratch[written] = uint8(ord(' '))
        inc written
      written = appendToken(textStorage, start, i, maskStorage, maskLength, scratch, written)
      haveToken = true
      start = i + 1
  if start < textLength:
    if haveToken:
      scratch[written] = uint8(ord(' '))
      inc written
    written = appendToken(textStorage, start, textLength, maskStorage, maskLength, scratch, written)
  if written > MaxOutputBytes: return -1
  if csize_t(written) > capacity or (written != 0 and output == nil): return -2
  for i in 0 ..< written: output[i] = scratch[i]
  int64(written)
