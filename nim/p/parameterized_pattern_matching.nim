const MaxText = 24
const MaxPattern = 8
const MaxInput = 34
const MaxOutputBytes = 200
const Alphabet = 16

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc predecessorCode(input: ptr UncheckedArray[int64], offset, count: int,
    code: var array[MaxPattern, int64]) =
  var last: array[Alphabet, int64]
  for symbol in 0 ..< Alphabet: last[symbol] = -1
  for index in 0 ..< count:
    let symbol = int(input[offset + index])
    code[index] = if last[symbol] < 0: 0 else: int64(index) - last[symbol]
    last[symbol] = int64(index)

proc parameterized_pattern_matching*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "parameterized_pattern_matching".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let textLengthValue = input[0]
  let patternLengthValue = input[1]
  if textLengthValue < 0 or textLengthValue > MaxText or
      patternLengthValue < 1 or patternLengthValue > MaxPattern: return -1
  let textLength = int(textLengthValue)
  let patternLength = int(patternLengthValue)
  if int(length) != 2 + textLength + patternLength: return -1
  for index in 2 ..< int(length):
    if input[index] < 0 or input[index] >= Alphabet: return -1

  var patternCode: array[MaxPattern, int64]
  predecessorCode(input, 2 + textLength, patternLength, patternCode)
  var matches: array[MaxText, int]
  var matchCount = 0
  if patternLength <= textLength:
    for start in 0 .. textLength - patternLength:
      var windowCode: array[MaxPattern, int64]
      predecessorCode(input, 2 + start, patternLength, windowCode)
      var same = true
      for index in 0 ..< patternLength:
        if patternCode[index] != windowCode[index]: same = false
      if same:
        matches[matchCount] = start
        inc matchCount

  let outputBytes = 8 * (matchCount + 1)
  if output.isNil or int(capacity) < outputBytes: return -2
  var staged: array[MaxOutputBytes, uint8]
  storeI64Le(addr staged[0], 0, int64(matchCount))
  for index in 0 ..< matchCount:
    storeI64Le(addr staged[0], 8 * (index + 1), int64(matches[index]))
  for index in 0 ..< outputBytes: output[index] = staged[index]
  int64(outputBytes)
