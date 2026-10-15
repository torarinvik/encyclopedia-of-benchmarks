## Add two most-significant-first binary digit arrays packed after their lengths.
proc binary_addition*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "binary_addition".} =
  if values.isNil or length < 2 or length > 4096:
    return -1
  let lengthAValue = values[0]
  let lengthBValue = values[1]
  if lengthAValue < 0 or lengthAValue > 2047 or lengthBValue < 0 or lengthBValue > 2047:
    return -1
  let lengthA = int(lengthAValue)
  let lengthB = int(lengthBValue)
  if length != csize_t(2 + lengthA + lengthB):
    return -1
  for index in 0 ..< lengthA:
    if values[2 + index] != 0 and values[2 + index] != 1:
      return -1
  for index in 0 ..< lengthB:
    if values[2 + lengthA + index] != 0 and values[2 + lengthA + index] != 1:
      return -1

  let width = max(lengthA, lengthB)
  var carry = 0
  for offset in 0 ..< width:
    let digitA = if offset < lengthA: values[2 + lengthA - 1 - offset] else: 0
    let digitB = if offset < lengthB: values[2 + lengthA + lengthB - 1 - offset] else: 0
    carry = (digitA + digitB + carry) shr 1
  let outputLength = width + carry
  if outputCapacity < csize_t(outputLength) or (outputLength > 0 and output.isNil):
    return -2

  carry = 0
  for offset in 0 ..< width:
    let digitA = if offset < lengthA: values[2 + lengthA - 1 - offset] else: 0
    let digitB = if offset < lengthB: values[2 + lengthA + lengthB - 1 - offset] else: 0
    let sum = digitA + digitB + carry
    output[width - 1 - offset] = uint8(ord('0') + int(sum and 1))
    carry = sum shr 1
  if carry != 0:
    output[0] = uint8(ord('1'))
  int64(outputLength)
