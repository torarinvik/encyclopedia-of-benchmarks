const MaxTextLength = 64
const MaxInputLength = MaxTextLength + 1
const MaxParseableInputLength = MaxInputLength + 2
const MaxOutputBytes = 4

proc isAsciiLetter(value: int64): bool =
  (value >= 65 and value <= 90) or (value >= 97 and value <= 122)

proc digitFor(inputValue: int64): int64 =
  var value = inputValue
  if value >= 65 and value <= 90: value += 32
  if value == 97 or value == 101 or value == 105 or value == 111 or value == 117 or value == 121: return 0
  if value == 104 or value == 119: return 8
  if value == 98 or value == 102 or value == 112 or value == 118: return 1
  if value == 99 or value == 103 or value == 106 or value == 107 or value == 113 or value == 115 or value == 120 or value == 122: return 2
  if value == 100 or value == 116: return 3
  if value == 108: return 4
  if value == 109 or value == 110: return 5
  if value == 114: return 6
  -1

proc soundex_encoder*(values: ptr UncheckedArray[int64], length: csize_t,
                      output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "soundex_encoder".} =
  if length < 1 or length > MaxParseableInputLength.csize_t or values.isNil:
    return -1
  let textLength = values[0]
  if textLength < 1 or textLength > MaxTextLength or length > MaxInputLength.csize_t or
      length != textLength.csize_t + 1: return -1
  for index in 1 ..< length.int:
    if not isAsciiLetter(values[index]): return -1

  var mapped: array[MaxTextLength, int64]
  var mappedCount = 0
  for index in 1 ..< length.int:
    var letter = values[index]
    if letter >= 65 and letter <= 90: letter += 32
    if letter == 104 or letter == 119: continue
    let digit = digitFor(letter)
    if mappedCount == 0 or mapped[mappedCount - 1] != digit:
      mapped[mappedCount] = digit
      inc mappedCount

  var codeCount = 0
  for index in 0 ..< mappedCount:
    if mapped[index] != 0:
      mapped[codeCount] = mapped[index]
      inc codeCount
  if codeCount == 0: return -1

  var firstLetter = values[1]
  if firstLetter >= 65 and firstLetter <= 90: firstLetter += 32
  var start = 0
  if mapped[0] == digitFor(firstLetter):
    if codeCount == 1: return -1
    start = 1

  var encoded: array[MaxOutputBytes, uint8]
  var initial = values[1]
  if initial >= 97 and initial <= 122: initial -= 32
  encoded[0] = uint8(initial)
  for index in 0 ..< 3:
    let digit = if start + index < codeCount: mapped[start + index] else: 0
    encoded[index + 1] = uint8(48 + digit)

  if output.isNil or outputCapacity < MaxOutputBytes.csize_t: return -2
  for index in 0 ..< MaxOutputBytes:
    output[index] = encoded[index]
  MaxOutputBytes.int64
