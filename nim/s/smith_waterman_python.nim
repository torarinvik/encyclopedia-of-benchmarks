const
  MaxSequenceLength = 16
  MaxParseableInputLength = 38
  ScoreStride = 17
  MaxOutputBytes = 1233

proc putU32LE(output: var array[MaxOutputBytes, uint8], position: var int, value: uint32) =
  var bits = value
  for _ in 0 ..< 4:
    output[position] = uint8(bits and 0xff'u32)
    bits = bits shr 8
    inc position

proc putI32LE(output: var array[MaxOutputBytes, uint8], position: var int, value: int64) =
  putU32LE(output, position, cast[uint32](int32(value)))

proc smith_waterman_python*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "smith_waterman_python".} =
  if input == nil or inputLength < 5 or inputLength > MaxParseableInputLength.csize_t: return -1
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
  if int(inputLength) != 5 + queryLength + subjectLength: return -1

  var query: array[MaxSequenceLength, int64]
  var subject: array[MaxSequenceLength, int64]
  for index in 0 ..< queryLength + subjectLength:
    var value = input[5 + index]
    if not ((value >= 65 and value <= 90) or (value >= 97 and value <= 122) or value == 45): return -1
    if value >= 97 and value <= 122: value -= 32
    if index < queryLength: query[index] = value
    else: subject[index - queryLength] = value

  var scores: array[ScoreStride * ScoreStride, int64]
  for row in 1 .. queryLength:
    for column in 1 .. subjectLength:
      var pairScore = mismatchScore
      if query[row - 1] == 45 or subject[column - 1] == 45: pairScore = gapScore
      elif query[row - 1] == subject[column - 1]: pairScore = matchScore
      let diagonal = scores[(row - 1) * ScoreStride + column - 1] + pairScore
      let above = scores[(row - 1) * ScoreStride + column] + gapScore
      let left = scores[row * ScoreStride + column - 1] + gapScore
      scores[row * ScoreStride + column] = max(0'i64, max(diagonal, max(above, left)))

  var maximum = -1'i64
  var maximumRow = 0
  var maximumColumn = 0
  for row in 0 .. queryLength:
    for column in 0 .. subjectLength:
      let value = scores[row * ScoreStride + column]
      if value > maximum:
        maximum = value
        maximumRow = row
        maximumColumn = column

  var traceQuery: array[2 * MaxSequenceLength, uint8]
  var traceSubject: array[2 * MaxSequenceLength, uint8]
  var traceLength = 0
  var row = maximumRow
  var column = maximumColumn
  while row > 0 and column > 0:
    var pairScore = -1'i64
    if query[row - 1] == 45 or subject[column - 1] == 45: pairScore = -2
    elif query[row - 1] == subject[column - 1]: pairScore = 1
    let diagonalScore = scores[(row - 1) * ScoreStride + column - 1] + pairScore
    let currentScore = scores[row * ScoreStride + column]
    if currentScore == diagonalScore:
      traceQuery[traceLength] = uint8(query[row - 1])
      traceSubject[traceLength] = uint8(subject[column - 1])
      dec row
      dec column
    elif currentScore == scores[(row - 1) * ScoreStride + column] - 2:
      traceQuery[traceLength] = uint8(query[row - 1])
      traceSubject[traceLength] = uint8('-')
      dec row
    else:
      traceQuery[traceLength] = uint8('-')
      traceSubject[traceLength] = uint8(subject[column - 1])
      dec column
    inc traceLength

  let alignmentLength = if traceLength == 0: 0 else: 2 * traceLength + 1
  var staged: array[MaxOutputBytes, uint8]
  var position = 0
  putU32LE(staged, position, uint32(queryLength + 1))
  putU32LE(staged, position, uint32(subjectLength + 1))
  for matrixRow in 0 .. queryLength:
    for matrixColumn in 0 .. subjectLength:
      putI32LE(staged, position, scores[matrixRow * ScoreStride + matrixColumn])
  putU32LE(staged, position, uint32(alignmentLength))
  for index in 0 ..< traceLength:
    staged[position] = traceQuery[traceLength - 1 - index]
    inc position
  if traceLength > 0:
    staged[position] = uint8('\n')
    inc position
  for index in 0 ..< traceLength:
    staged[position] = traceSubject[traceLength - 1 - index]
    inc position

  if output == nil or outputCapacity < position.csize_t: return -2
  for index in 0 ..< position: output[index] = staged[index]
  int64(position)
