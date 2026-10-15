## Case-insensitive anagram check for distinct ASCII alphabetic strings.
const MaxStringLength = 1024
const MaxInputLength = 2 + 2 * MaxStringLength

func letterIndex(value: int64): int =
  if value >= 97 and value <= 122: return int(value - 97)
  if value >= 65 and value <= 90: return int(value - 65)
  -1

proc check_anagram*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "check_anagram".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let firstLengthValue = input[0]
  let secondLengthValue = input[1]
  if firstLengthValue < 0 or firstLengthValue > MaxStringLength or
      secondLengthValue < 0 or secondLengthValue > MaxStringLength: return -1
  let firstLength = int(firstLengthValue)
  let secondLength = int(secondLengthValue)
  if int(length) != 2 + firstLength + secondLength: return -1
  var firstCounts: array[26, int]
  var secondCounts: array[26, int]
  for index in 0 ..< firstLength:
    let letter = letterIndex(input[2 + index])
    if letter < 0: return -1
    inc firstCounts[letter]
  for index in 0 ..< secondLength:
    let letter = letterIndex(input[2 + firstLength + index])
    if letter < 0: return -1
    inc secondCounts[letter]
  if firstLength != secondLength: return 0
  var differentAfterNormalization = false
  for index in 0 ..< firstLength:
    if letterIndex(input[2 + index]) != letterIndex(input[2 + firstLength + index]):
      differentAfterNormalization = true
  if not differentAfterNormalization: return 0
  if firstCounts != secondCounts: return 0
  1
