## Check for a permutation of one lowercase ASCII string inside another.
const MaxStringLength = 1024
const MaxInputLength = 2 + 2 * MaxStringLength

proc adjustCount(differences: var array[26, int64], nonzero: var int64,
                 letter: int, amount: int64) =
  if differences[letter] == 0: inc nonzero
  differences[letter] += amount
  if differences[letter] == 0: dec nonzero

proc permutation_in_string*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "permutation_in_string".} =
  if length < 2 or length > csize_t(MaxInputLength): return -1
  let firstLengthValue = input[0]
  let secondLengthValue = input[1]
  if firstLengthValue < 0 or firstLengthValue > MaxStringLength or
      secondLengthValue < 0 or secondLengthValue > MaxStringLength: return -1
  let firstLength = int(firstLengthValue)
  let secondLength = int(secondLengthValue)
  if int(length) != 2 + firstLength + secondLength: return -1
  for index in 2 ..< int(length):
    if input[index] < 97 or input[index] > 122: return -1
  if firstLength > secondLength: return 0

  var differences: array[26, int64]
  var nonzero = 0'i64
  for index in 0 ..< firstLength:
    adjustCount(differences, nonzero, int(input[2 + index] - 97), 1)
    adjustCount(differences, nonzero, int(input[2 + firstLength + index] - 97), -1)
  if nonzero == 0: return 1
  for start in 0 ..< secondLength - firstLength:
    let outgoing = 2 + firstLength + start
    let incoming = outgoing + firstLength
    adjustCount(differences, nonzero, int(input[outgoing] - 97), 1)
    adjustCount(differences, nonzero, int(input[incoming] - 97), -1)
    if nonzero == 0: return 1
  0
