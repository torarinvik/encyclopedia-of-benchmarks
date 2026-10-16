const MaxParseableInputLength = 258

proc isTrimByte(value: int64): bool = value >= 0 and value <= 32
proc isSplitSpace(value: int64): bool = value == 32 or (value >= 9 and value <= 13)

proc reverse_words_in_string*(input: ptr UncheckedArray[int64], length: csize_t,
                              output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "reverse_words_in_string".} =
  if input.isNil or length == 0 or length > MaxParseableInputLength: return -1
  if input[0] < 0 or input[0] > 256: return -1
  let textLength = int(input[0])
  if int(length) != textLength + 1: return -1
  for i in 0 ..< textLength:
    if input[i + 1] < 0 or input[i + 1] > 127: return -1

  var start = 0
  var finish = textLength
  while start < finish and isTrimByte(input[start + 1]): inc start
  while finish > start and isTrimByte(input[finish]): dec finish

  var outputLength = 0
  var wordCount = 0
  var position = start
  while position < finish:
    while position < finish and isSplitSpace(input[position + 1]): inc position
    if position < finish:
      let tokenStart = position
      while position < finish and not isSplitSpace(input[position + 1]): inc position
      outputLength += position - tokenStart
      if wordCount > 0: inc outputLength
      inc wordCount
  if capacity < outputLength or (outputLength > 0 and output.isNil): return -2

  var written = 0
  var emitted = 0
  position = finish
  while position > start:
    while position > start and isSplitSpace(input[position]): dec position
    if position > start:
      let tokenEnd = position
      while position > start and not isSplitSpace(input[position]): dec position
      let tokenStart = position
      if emitted > 0:
        output[written] = uint8(32)
        inc written
      for i in tokenStart ..< tokenEnd:
        output[written] = uint8(input[i + 1])
        inc written
      inc emitted
  int64(written)
