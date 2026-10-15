## Compare lowercase ASCII strings by their letter frequencies.
const MaxStringLength = 1024
const MaxInputLength = 2 + 2 * MaxStringLength

proc valid_anagram*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "valid_anagram".} =
  if length < 2 or length > csize_t(MaxInputLength): return -1
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
    let value = input[2 + index]
    if value < 97 or value > 122: return -1
    inc firstCounts[int(value - 97)]
  for index in 0 ..< secondLength:
    let value = input[2 + firstLength + index]
    if value < 97 or value > 122: return -1
    inc secondCounts[int(value - 97)]
  for letter in 0 ..< 26:
    if firstCounts[letter] != secondCounts[letter]: return 0
  1
