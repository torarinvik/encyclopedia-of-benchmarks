proc big_integer_multiply*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "big_integer_multiply".} =
  if input.isNil or length < 4 or length > 66: return -1
  let leftValue = input[0]
  let rightValue = input[1]
  if leftValue < 1 or leftValue > 32 or rightValue < 1 or rightValue > 32: return -1
  let leftLength = int(leftValue)
  let rightLength = int(rightValue)
  if int(length) != 2 + leftLength + rightLength: return -1
  let rightStart = 2 + leftLength
  for index in 0..<leftLength:
    if input[2 + index] < 48 or input[2 + index] > 57: return -1
  for index in 0..<rightLength:
    if input[rightStart + index] < 48 or input[rightStart + index] > 57: return -1
  if (leftLength > 1 and input[2] == 48) or
     (rightLength > 1 and input[rightStart] == 48): return -1

  var product: array[64, uint16]
  let productSize = leftLength + rightLength
  let isZero = (leftLength == 1 and input[2] == 48) or
               (rightLength == 1 and input[rightStart] == 48)
  if not isZero:
    for i in 0..<leftLength:
      for j in 0..<rightLength:
        let position = i + j
        let leftDigit = input[2 + leftLength - i - 1]
        let rightDigit = input[rightStart + rightLength - j - 1]
        let multiplication = uint16((leftDigit - 48) * (rightDigit - 48))
        product[position + 1] += (product[position] + multiplication) div 10
        product[position] = (product[position] + multiplication) mod 10
  let effectiveSize = if isZero: 1 elif product[productSize - 1] == 0: productSize - 1 else: productSize
  if output.isNil or capacity < csize_t(effectiveSize): return -2
  if isZero:
    output[0] = uint8(48)
  else:
    for index in 0..<effectiveSize:
      output[index] = uint8(48 + product[effectiveSize - index - 1])
  int64(effectiveSize)
