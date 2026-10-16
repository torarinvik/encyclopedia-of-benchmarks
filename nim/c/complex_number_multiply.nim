type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc parseComponent(input: I64Input, start, ending: int): int64 =
  var position = start
  var negative = false
  if position < ending and input[position] == 45:
    negative = true
    inc position
  if position == ending: return -32768
  var magnitude = 0'i64
  while position < ending:
    if input[position] < 48 or input[position] > 57: return -32768
    let digit = input[position] - 48
    if magnitude > (32767 - digit) div 10: return -32768
    magnitude = magnitude * 10 + digit
    inc position
  if negative: -magnitude else: magnitude

proc parseComplex(input: I64Input, start, textLength: int,
                  real, imaginary: var int64): bool =
  if textLength < 4 or textLength > 64 or input[start + textLength - 1] != 105: return false
  var separator = -1
  for index in 0 ..< (textLength - 1):
    if input[start + index] == 43:
      if separator >= 0: return false
      separator = index
  if separator < 0: return false
  real = parseComponent(input, start, start + separator)
  imaginary = parseComponent(input, start + separator + 1, start + textLength - 1)
  real != -32768 and imaginary != -32768

proc decimalLength(value: int64): int =
  var magnitude = value
  var result = if value < 0: 1 else: 0
  if magnitude < 0: magnitude = -magnitude
  if magnitude == 0: return result + 1
  while magnitude > 0:
    inc result
    magnitude = magnitude div 10
  result

proc appendDecimal(output: U8Output, index: var int, value: int64) =
  var magnitude = value
  if magnitude < 0:
    output[index] = 45'u8
    inc index
    magnitude = -magnitude
  let start = index
  if magnitude == 0:
    output[index] = 48'u8
    inc index
    return
  while magnitude > 0:
    output[index] = uint8(48 + magnitude mod 10)
    inc index
    magnitude = magnitude div 10
  var left = start
  var right = index - 1
  while left < right:
    swap(output[left], output[right])
    inc left
    dec right

proc complex_number_multiply*(input: I64Input, length: csize_t,
    output: U8Output, capacity: csize_t): int64 {.cdecl, exportc: "complex_number_multiply".} =
  if input == nil or length < 2 or length > csize_t(130): return -1
  let rawLeftLength = input[0]
  let rawRightLength = input[1]
  if rawLeftLength < 4 or rawLeftLength > 64 or rawRightLength < 4 or rawRightLength > 64: return -1
  let leftLength = int(rawLeftLength)
  let rightLength = int(rawRightLength)
  if length != csize_t(2 + leftLength + rightLength): return -1
  for index in 2 ..< int(length):
    if input[index] < 0 or input[index] > 127: return -1

  var leftReal, leftImaginary, rightReal, rightImaginary: int64
  if not parseComplex(input, 2, leftLength, leftReal, leftImaginary)
      or not parseComplex(input, 2 + leftLength, rightLength, rightReal, rightImaginary): return -1
  let real = leftReal * rightReal - leftImaginary * rightImaginary
  let imaginary = leftReal * rightImaginary + leftImaginary * rightReal
  let needed = decimalLength(real) + decimalLength(imaginary) + 2
  if output == nil or capacity < csize_t(needed): return -2

  var written = 0
  appendDecimal(output, written, real)
  output[written] = 43'u8
  inc written
  appendDecimal(output, written, imaginary)
  output[written] = 105'u8
  inc written
  int64(written)
