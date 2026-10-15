## Count non-overlapping PHP-style sentence-regex matches in bounded ASCII.
const MaxTextLength = 4096

proc isTrimByte(value: uint8): bool =
  value == 0 or value == 9 or value == 10 or value == 11 or value == 13 or value == 32

proc isRegexSpace(value: uint8): bool =
  (value >= 9 and value <= 13) or value == 32

proc isWordByte(value: uint8): bool =
  (value >= 65 and value <= 90) or (value >= 97 and value <= 122) or
    (value >= 48 and value <= 57) or value == 95

proc isTerminator(value: uint8): bool = value == 46 or value == 33 or value == 63

proc isEligiblePredecessor(value: uint8): bool =
  not isRegexSpace(value) and value != 124 and value != 94 and value != 46

proc count_sentences*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "count_sentences".} =
  if input == nil or length < 1 or length > csize_t(MaxTextLength + 1): return -1
  if input[0] < 0 or input[0] > int64(MaxTextLength) or length != csize_t(input[0] + 1): return -1
  let textLength = int(input[0])
  var text: array[MaxTextLength, uint8]
  for index in 0 ..< textLength:
    if input[index + 1] < 0 or input[index + 1] > 127: return -1
    text[index] = uint8(input[index + 1])

  var beginIndex = 0
  var endIndex = textLength
  while beginIndex < endIndex and isTrimByte(text[beginIndex]): inc beginIndex
  while endIndex > beginIndex and isTrimByte(text[endIndex - 1]): dec endIndex
  var cursor = beginIndex
  var count = 0'i64
  while cursor + 1 < endIndex:
    var found = false
    var index = cursor
    while index + 1 < endIndex:
      if isEligiblePredecessor(text[index]) and isTerminator(text[index + 1]) and
          (index + 2 == endIndex or not isWordByte(text[index + 2])):
        inc count
        cursor = index + 2
        found = true
        break
      inc index
    if not found: break
  count
