proc compareWords(values: ptr UncheckedArray[int64], startA, lengthA, startB, lengthB: int): int =
  let common = min(lengthA, lengthB)
  for index in 0 ..< common:
    let a = values[1 + startA + index]
    let b = values[1 + startB + index]
    if a < b: return -1
    if a > b: return 1
  if lengthA < lengthB: return -1
  if lengthA > lengthB: return 1
  0

proc remove_duplicate*(values: ptr UncheckedArray[int64], length: csize_t,
                       output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "remove_duplicate".} =
  if values == nil or length < 1 or values[0] < 0 or values[0] > 1024 or
      length != csize_t(1 + values[0]): return -1
  let textLength = int(values[0])
  for index in 0 ..< textLength:
    let byte = values[index + 1]
    if byte != 32 and (byte < 97 or byte > 122): return -1
  var starts: array[512, int]
  var wordLengths: array[512, int]
  var wordCount = 0
  var cursor = 0
  while cursor < textLength:
    if values[cursor + 1] == 32:
      inc cursor
      continue
    starts[wordCount] = cursor
    while cursor < textLength and values[cursor + 1] != 32: inc cursor
    wordLengths[wordCount] = cursor - starts[wordCount]
    inc wordCount
  for index in 1 ..< wordCount:
    let keyStart = starts[index]
    let keyLength = wordLengths[index]
    var position = index
    while position > 0 and compareWords(values, starts[position - 1], wordLengths[position - 1],
                                        keyStart, keyLength) > 0:
      starts[position] = starts[position - 1]
      wordLengths[position] = wordLengths[position - 1]
      dec position
    starts[position] = keyStart
    wordLengths[position] = keyLength
  var outputLength = 0
  var uniqueCount = 0
  for index in 0 ..< wordCount:
    if index > 0 and compareWords(values, starts[index - 1], wordLengths[index - 1],
                                  starts[index], wordLengths[index]) == 0: continue
    if uniqueCount > 0: inc outputLength
    outputLength += wordLengths[index]
    inc uniqueCount
  if outputLength > int(outputCapacity) or (outputLength > 0 and output == nil): return -2
  var written = 0
  var emitted = 0
  for index in 0 ..< wordCount:
    if index > 0 and compareWords(values, starts[index - 1], wordLengths[index - 1],
                                  starts[index], wordLengths[index]) == 0: continue
    if emitted > 0:
      output[written] = uint8(' ')
      inc written
    for byte in 0 ..< wordLengths[index]:
      output[written] = uint8(values[1 + starts[index] + byte])
      inc written
    inc emitted
  int64(outputLength)
