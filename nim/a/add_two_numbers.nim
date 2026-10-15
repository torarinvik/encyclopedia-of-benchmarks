## Add reverse-order decimal digit lists with a carry propagated per node.
const MaxDigits = 1024

proc add_two_numbers*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "add_two_numbers".} =
  if input == nil or length < 2 or length > csize_t(2 + 2 * MaxDigits): return -1
  if input[0] < 0 or input[0] > MaxDigits or input[1] < 0 or input[1] > MaxDigits: return -1
  let firstLength = csize_t(input[0])
  let secondLength = csize_t(input[1])
  if length != firstLength + secondLength + 2: return -1
  for index in 0 ..< int(firstLength + secondLength):
    if input[index + 2] < 0 or input[index + 2] > 9: return -1
  let digitCount = max(firstLength, secondLength)
  var digits: array[MaxDigits + 1, uint8]
  var resultLength: csize_t = 0
  var carry: int64 = 0
  var index: csize_t = 0
  while index < digitCount or carry != 0:
    let first = if index < firstLength: input[index + 2] else: 0
    let second = if index < secondLength: input[index + 2 + firstLength] else: 0
    let sum = first + second + carry
    digits[resultLength] = uint8(sum mod 10)
    inc resultLength
    carry = sum div 10
    inc index
  if outputCapacity < resultLength or (resultLength != 0 and output == nil): return -2
  for position in 0 ..< int(resultLength): output[position] = digits[position]
  int64(resultLength)
