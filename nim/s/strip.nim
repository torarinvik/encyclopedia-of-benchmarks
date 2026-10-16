const MaxTextLength = 256
const MaxCharacterLength = 128

proc stripContains(value: int64, input: ptr UncheckedArray[int64], setStart: int,
                   setLength: int64): bool =
  if setLength == -1:
    return value == 9 or value == 10 or value == 13 or value == 32
  for index in 0 ..< int(setLength):
    if input[setStart + index] == value: return true
  false

proc strip*(input: ptr UncheckedArray[int64], length: csize_t,
            output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "strip".} =
  if input.isNil or length < 2 or length > 386: return -1
  if input[0] < 0 or input[0] > MaxTextLength: return -1
  let textLength = int(input[0])
  let setIndex = 1 + textLength
  if setIndex >= int(length): return -1
  let setLength = input[setIndex]
  var expectedLength: int
  if setLength == -1:
    expectedLength = setIndex + 1
  else:
    if setLength < 0 or setLength > MaxCharacterLength: return -1
    expectedLength = setIndex + 1 + int(setLength)
  if int(length) != expectedLength: return -1
  for index in 0 ..< textLength:
    if input[1 + index] < 0 or input[1 + index] > 127: return -1
  if setLength >= 0:
    for index in 0 ..< int(setLength):
      if input[setIndex + 1 + index] < 0 or input[setIndex + 1 + index] > 127: return -1

  var start = 0
  var ending = textLength
  while start < ending and stripContains(input[1 + start], input, setIndex + 1, setLength):
    inc start
  while ending > start and stripContains(input[ending], input, setIndex + 1, setLength):
    dec ending
  let outputLength = ending - start
  if outputCapacity < csize_t(outputLength) or (outputLength > 0 and output.isNil): return -2
  for index in 0 ..< outputLength:
    output[index] = uint8(input[1 + start + index])
  int64(outputLength)
