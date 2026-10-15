const MaxStringLength = 16
const MaxCandidates = 16
const MaxInputLength = 290

proc isAsciiLetter(value: int64): bool =
  (value >= 65 and value <= 90) or (value >= 97 and value <= 122)

proc lowerAscii(value: int64): int64 =
  if value >= 65 and value <= 90: value + 32 else: value

proc detect_anagrams*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "detect_anagrams".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let count = int(length)
  let subjectLengthValue = input[0]
  if subjectLengthValue < 0 or subjectLengthValue > MaxStringLength: return -1
  let subjectLength = int(subjectLengthValue)
  var position = 1
  var subjectCounts: array[26, int]
  for index in 0 ..< subjectLength:
    let value = input[position + index]
    if not isAsciiLetter(value): return -1
    inc subjectCounts[int(lowerAscii(value) - 97)]
  position += subjectLength
  if position >= count: return -1

  let candidateCountValue = input[position]
  if candidateCountValue < 0 or candidateCountValue > MaxCandidates: return -1
  let candidateCount = int(candidateCountValue)
  inc position
  var candidateStarts: array[MaxCandidates, int]
  var candidateLengths: array[MaxCandidates, int]
  var selected: array[MaxCandidates, bool]
  var matchCount = 0
  var outputLength = 0

  for candidate in 0 ..< candidateCount:
    if position >= count: return -1
    let candidateLengthValue = input[position]
    if candidateLengthValue < 0 or candidateLengthValue > MaxStringLength: return -1
    let candidateLength = int(candidateLengthValue)
    inc position
    if candidateLength > count - position: return -1
    candidateStarts[candidate] = position
    candidateLengths[candidate] = candidateLength
    var candidateCounts: array[26, int]
    var sameIdentity = candidateLength == subjectLength
    for index in 0 ..< candidateLength:
      let value = input[position + index]
      if not isAsciiLetter(value): return -1
      inc candidateCounts[int(lowerAscii(value) - 97)]
      if sameIdentity and lowerAscii(value) != lowerAscii(input[1 + index]): sameIdentity = false
    var sameSignature = true
    for letter in 0 ..< 26:
      if candidateCounts[letter] != subjectCounts[letter]: sameSignature = false
    if sameSignature and not sameIdentity:
      selected[candidate] = true
      inc matchCount
      outputLength += candidateLength + 1
    position += candidateLength

  if position != count: return -1
  let required = csize_t(outputLength + 1)
  if output.isNil or capacity < required: return -2
  var written = 0
  for candidate in 0 ..< candidateCount:
    if selected[candidate]:
      for index in 0 ..< candidateLengths[candidate]:
        output[written] = uint8(input[candidateStarts[candidate] + index])
        inc written
      output[written] = 10
      inc written
  output[written] = 0
  int64(matchCount)
