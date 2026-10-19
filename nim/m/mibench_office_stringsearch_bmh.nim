## Modified derivative of MiBench bmhsrch.c; public domain by Raymond Gardner (7/92).
const MaxText = 128
const MaxPattern = 32
const MaxInput = 162

proc mibenchOfficeStringsearchBmh*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "mibench_office_stringsearch_bmh".} =
  if input == nil or length < 2 or length > csize_t(MaxInput): return -1
  let textLengthValue = input[0]
  let patternLengthValue = input[1]
  if textLengthValue < 0 or textLengthValue > MaxText or
      patternLengthValue < 1 or patternLengthValue > MaxPattern: return -1
  let textLength = int(textLengthValue)
  let patternLength = int(patternLengthValue)
  if int(length) != 2 + textLength + patternLength: return -1
  var text: array[MaxText, uint8]
  var pattern: array[MaxPattern, uint8]
  for i in 0 ..< textLength + patternLength:
    let value = input[2 + i]
    if value < 32 or value > 126: return -1
    if i < textLength: text[i] = uint8(value)
    else: pattern[i - textLength] = uint8(value)
  var shift: array[256, int]
  for i in 0 ..< 256: shift[i] = patternLength
  for i in 0 ..< patternLength - 1:
    shift[int(pattern[i])] = patternLength - i - 1
  var match: int64 = -1
  if patternLength <= textLength:
    var start = 0
    while start <= textLength - patternLength:
      var j = patternLength
      while j > 0 and text[start + j - 1] == pattern[j - 1]: dec j
      if j == 0:
        match = int64(start)
        break
      start += shift[int(text[start + patternLength - 1])]
  if output == nil or outputCapacity < 8: return -2
  let bits = cast[uint64](match)
  for i in 0 ..< 8: output[i] = uint8((bits shr (8 * i)) and 255)
  8
