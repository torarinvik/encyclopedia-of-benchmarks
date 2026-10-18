const
  MaxSequenceLength = 16
  MaxParseableInputLength = 38
  ScoreStride = 17

proc smith_waterman_java*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "smith_waterman_java".} =
  if input == nil or length < 5 or length > MaxParseableInputLength.csize_t: return -1
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
  if length != csize_t(5 + queryLength + subjectLength): return -1
  for index in 5 ..< int(length):
    let value = input[index]
    if not ((value >= 65 and value <= 90) or (value >= 97 and value <= 122) or value == 45): return -1

  var scores: array[ScoreStride * ScoreStride, int64]
  var maximum = 0'i64
  for row in 1 .. queryLength:
    for column in 1 .. subjectLength:
      let queryChar = input[4 + row]
      let subjectChar = input[4 + queryLength + column]
      let pairScore = if queryChar == subjectChar: matchScore else: mismatchScore
      let diagonal = scores[(row - 1) * ScoreStride + column - 1] + pairScore
      let above = scores[(row - 1) * ScoreStride + column] + gapScore
      let left = scores[row * ScoreStride + column - 1] + gapScore
      var value = max(0'i64, max(diagonal, max(above, left)))
      scores[row * ScoreStride + column] = value
      if value > maximum: maximum = value
  maximum
