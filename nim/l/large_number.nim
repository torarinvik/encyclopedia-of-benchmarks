const MaxParseableInputLength = 131
const MaxDigits = 64

proc large_number_add*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "large_number_add".} =
  if input == nil or inputLength < 2 or inputLength > MaxParseableInputLength.csize_t: return -1
  let leftLengthValue = input[0]
  let rightLengthValue = input[1]
  if leftLengthValue < 1 or leftLengthValue > MaxDigits or
      rightLengthValue < 1 or rightLengthValue > MaxDigits: return -1
  let leftLength = int(leftLengthValue)
  let rightLength = int(rightLengthValue)
  if inputLength != csize_t(2 + leftLength + rightLength): return -1

  var left, right: array[MaxDigits, uint8]
  for i in 0 ..< leftLength:
    let digit = input[2 + i]
    if digit < 48 or digit > 57 or (i == 0 and leftLength > 1 and digit == 48): return -1
    left[leftLength - i - 1] = uint8(digit - 48)
  for i in 0 ..< rightLength:
    let digit = input[2 + leftLength + i]
    if digit < 48 or digit > 57 or (i == 0 and rightLength > 1 and digit == 48): return -1
    right[rightLength - i - 1] = uint8(digit - 48)

  var sum: array[MaxDigits + 1, uint8]
  var sumLength = 0
  var carry = 0
  while sumLength < max(leftLength, rightLength) or carry != 0:
    var total = carry
    if sumLength < rightLength: total += int(right[sumLength])
    if sumLength < leftLength: total += int(left[sumLength])
    sum[sumLength] = uint8(total mod 10)
    carry = total div 10
    inc sumLength
  var staged: array[MaxDigits + 1, uint8]
  for i in 0 ..< sumLength: staged[i] = uint8(ord('0')) + sum[sumLength - i - 1]
  if output == nil or outputCapacity < csize_t(sumLength): return -2
  for i in 0 ..< sumLength: output[i] = staged[i]
  int64(sumLength)
