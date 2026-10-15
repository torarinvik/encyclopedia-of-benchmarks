## Check lowercase strings for equal letter sets and frequency multisets.
proc close_strings*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "close_strings".} =
  if length < 2 or length > 514 or input.isNil: return -1
  let firstLengthValue = input[0]
  let secondLengthValue = input[1]
  if firstLengthValue < 0 or firstLengthValue > 256 or
      secondLengthValue < 0 or secondLengthValue > 256: return -1
  let firstLength = int(firstLengthValue)
  let secondLength = int(secondLengthValue)
  if int(length) != 2 + firstLength + secondLength: return -1
  var first: array[26, int64]
  var second: array[26, int64]
  for index in 0 ..< firstLength:
    let value = input[index + 2]
    if value < 97 or value > 122: return -1
    inc first[int(value - 97)]
  let secondStart = 2 + firstLength
  for index in 0 ..< secondLength:
    let value = input[secondStart + index]
    if value < 97 or value > 122: return -1
    inc second[int(value - 97)]
  if firstLength != secondLength: return 0
  var firstFrequencies: array[257, int64]
  var secondFrequencies: array[257, int64]
  for letter in 0 ..< 26:
    if (first[letter] == 0) != (second[letter] == 0): return 0
    inc firstFrequencies[int(first[letter])]
    inc secondFrequencies[int(second[letter])]
  if firstFrequencies == secondFrequencies: 1 else: 0
