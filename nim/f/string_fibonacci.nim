const MaxN = 256
const DecimalCapacity = 80

proc addDecimal(left, right: array[DecimalCapacity, char], leftLength, rightLength: int,
                result: var array[DecimalCapacity, char]): int =
  var reversed: array[DecimalCapacity, char]
  var leftRemaining = leftLength
  var rightRemaining = rightLength
  var length = 0
  var carry = 0
  while leftRemaining > 0 or rightRemaining > 0 or carry != 0:
    var leftDigit = 0
    var rightDigit = 0
    if leftRemaining > 0:
      dec leftRemaining
      leftDigit = ord(left[leftRemaining]) - ord('0')
    if rightRemaining > 0:
      dec rightRemaining
      rightDigit = ord(right[rightRemaining]) - ord('0')
    let sum = leftDigit + rightDigit + carry
    reversed[length] = char(ord('0') + (sum mod 10))
    inc length
    carry = sum div 10
  for i in 0 ..< length:
    result[i] = reversed[length - 1 - i]
  result[length] = '\0'
  length

proc string_fibonacci*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "string_fibonacci".} =
  if input == nil or length != 1: return -1
  let n = input[0]
  if n < 0 or n > MaxN: return -1

  var fibMinusOne: array[DecimalCapacity, char]
  var fibMinusTwo: array[DecimalCapacity, char]
  fibMinusOne[0] = '1'
  fibMinusTwo[0] = '0'
  var minusOneLength = 1
  var minusTwoLength = 1
  for _ in 0 ..< int(n):
    var sum: array[DecimalCapacity, char]
    let sumLength = addDecimal(fibMinusOne, fibMinusTwo, minusOneLength, minusTwoLength, sum)
    for i in 0 ..< minusOneLength:
      fibMinusTwo[i] = fibMinusOne[i]
    minusTwoLength = minusOneLength
    for i in 0 ..< sumLength:
      fibMinusOne[i] = sum[i]
    fibMinusOne[sumLength] = '\0'
    minusOneLength = sumLength

  if output == nil or capacity < csize_t(minusTwoLength): return -2
  for i in 0 ..< minusTwoLength:
    output[i] = uint8(ord(fibMinusTwo[i]))
  int64(minusTwoLength)
