const MaxSequenceLength = 16
const MaxParseableInputLength = 38
const MaxOutputBytes = 1233
const MatrixStride = 17
const MatrixCells = 289
const MaxTraceSteps = 32

proc writeU32(output: var array[MaxOutputBytes, uint8], offset: int, value: uint32) =
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((value shr (byte * 8)) and 0xFF'u32)

proc writeI32(output: var array[MaxOutputBytes, uint8], offset: int, value: int64) =
  let bits = cast[uint32](int32(value))
  writeU32(output, offset, bits)

proc smith_waterman_rust*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "smith_waterman_rust".} =
  if input == nil or length < csize_t(5) or length > csize_t(MaxParseableInputLength):
    return -1
  let queryLengthValue = input[0]
  let subjectLengthValue = input[1]
  let matchScore = input[2]
  let mismatchScore = input[3]
  let gapScore = input[4]
  if queryLengthValue < 0 or queryLengthValue > MaxSequenceLength or
      subjectLengthValue < 0 or subjectLengthValue > MaxSequenceLength or
      matchScore < 1 or matchScore > 5 or mismatchScore < -5 or mismatchScore > -1 or
      gapScore < -5 or gapScore > -1: return -1

  let queryLength = int(queryLengthValue)
  let subjectLength = int(subjectLengthValue)
  if int(length) != 5 + queryLength + subjectLength: return -1

  var query: array[16, uint8]
  var subject: array[16, uint8]
  for index in 0 ..< (queryLength + subjectLength):
    let value = input[index + 5]
    if not ((value >= 65 and value <= 90) or (value >= 97 and value <= 122) or value == 45):
      return -1
    let upper = if value >= 97: value - 32 else: value
    if index < queryLength:
      query[index] = uint8(upper)
    else:
      subject[index - queryLength] = uint8(upper)

  var scores: array[MatrixCells, int64]
  for row in 1 ..< (queryLength + 1):
    for column in 1 ..< (subjectLength + 1):
      let queryChar = int64(query[row - 1])
      let subjectChar = int64(subject[column - 1])
      let pairScore = if queryChar == 45 or subjectChar == 45: gapScore
                      elif queryChar == subjectChar: matchScore
                      else: mismatchScore
      let diagonal = scores[(row - 1) * MatrixStride + column - 1] + pairScore
      let above = scores[(row - 1) * MatrixStride + column] + gapScore
      let left = scores[row * MatrixStride + column - 1] + gapScore
      scores[row * MatrixStride + column] = max(0'i64, max(diagonal, max(above, left)))

  var maximum = 0'i64
  var maximumRow = 0
  var maximumColumn = 0
  for row in 0 ..< (queryLength + 1):
    for column in 0 ..< (subjectLength + 1):
      let value = scores[row * MatrixStride + column]
      if value > maximum:
        maximum = value
        maximumRow = row
        maximumColumn = column

  var alignQuery: array[MaxTraceSteps, uint8]
  var alignSubject: array[MaxTraceSteps, uint8]
  var traceCount = 0
  var row = maximumRow
  var column = maximumColumn
  while row > 0 and column > 0 and scores[row * MatrixStride + column] > 0:
    let current = scores[row * MatrixStride + column]
    let queryChar = int64(query[row - 1])
    let subjectChar = int64(subject[column - 1])
    let pairScore = if queryChar == 45 or subjectChar == 45: gapScore
                    elif queryChar == subjectChar: matchScore
                    else: mismatchScore
    let diagonal = scores[(row - 1) * MatrixStride + column - 1] + pairScore
    if current == diagonal:
      alignQuery[traceCount] = query[row - 1]
      alignSubject[traceCount] = subject[column - 1]
      dec row
      dec column
    elif current == scores[(row - 1) * MatrixStride + column] + gapScore:
      alignQuery[traceCount] = query[row - 1]
      alignSubject[traceCount] = uint8(45)
      dec row
    else:
      alignQuery[traceCount] = uint8(45)
      alignSubject[traceCount] = subject[column - 1]
      dec column
    inc traceCount

  let rows = queryLength + 1
  let columns = subjectLength + 1
  let alignmentLength = if traceCount == 0: 0 else: traceCount * 2 + 1
  let payloadLength = 8 + rows * columns * 4 + 4 + alignmentLength
  if payloadLength > MaxOutputBytes: return -1
  if output == nil or outputCapacity < csize_t(payloadLength): return -2

  var payload: array[MaxOutputBytes, uint8]
  var position = 0
  writeU32(payload, position, uint32(rows))
  position += 4
  writeU32(payload, position, uint32(columns))
  position += 4
  for matrixRow in 0 ..< rows:
    for matrixColumn in 0 ..< columns:
      writeI32(payload, position, scores[matrixRow * MatrixStride + matrixColumn])
      position += 4
  writeU32(payload, position, uint32(alignmentLength))
  position += 4
  if traceCount > 0:
    for index in 0 ..< traceCount:
      payload[position + index] = alignQuery[traceCount - index - 1]
    payload[position + traceCount] = uint8(10)
    for index in 0 ..< traceCount:
      payload[position + traceCount + 1 + index] = alignSubject[traceCount - index - 1]
  for index in 0 ..< payloadLength:
    output[index] = payload[index]
  int64(payloadLength)
