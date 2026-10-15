## Check a Unicode scalar subsequence using a greedy forward scan.
const MaxSequenceLength = 4096
const MaxPackedLength = 8194

proc isUnicodeScalar(value: int64): bool =
  value >= 0 and value <= 1_114_111 and not (value >= 55_296 and value <= 57_343)

proc is_subsequence*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "is_subsequence".} =
  if input == nil or length < 2 or length > csize_t(MaxPackedLength): return -1
  if input[0] < 0 or input[0] > int64(MaxSequenceLength) or
      input[1] < 0 or input[1] > int64(MaxSequenceLength): return -1
  let mainLength = int(input[0])
  let subsequenceLength = int(input[1])
  if int(length) != 2 + mainLength + subsequenceLength: return -1
  for index in 2 ..< int(length):
    if not isUnicodeScalar(input[index]): return -1

  let subsequenceStart = 2 + mainLength
  var mainIndex = 0
  var subsequenceIndex = 0
  while subsequenceIndex < subsequenceLength and mainIndex < mainLength:
    if input[subsequenceStart + subsequenceIndex] == input[2 + mainIndex]: inc subsequenceIndex
    inc mainIndex
  if subsequenceIndex == subsequenceLength: 1 else: 0
