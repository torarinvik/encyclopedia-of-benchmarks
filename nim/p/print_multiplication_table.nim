proc decimalLength(value: int64): int =
  var magnitude = value
  result = 1
  if magnitude < 0:
    inc result
    magnitude = -magnitude
  while magnitude >= 10:
    magnitude = magnitude div 10
    inc result

proc appendDecimal(output: ptr UncheckedArray[uint8], position: var int, value: int64) =
  var magnitude = value
  if magnitude < 0:
    output[position] = uint8(ord('-'))
    inc position
    magnitude = -magnitude
  var digits: array[20, uint8]
  var count = 0
  while magnitude > 0:
    digits[count] = uint8(ord('0') + int(magnitude mod 10))
    inc count
    magnitude = magnitude div 10
  if count == 0:
    digits[0] = uint8(ord('0'))
    count = 1
  while count > 0:
    dec count
    output[position] = digits[count]
    inc position

proc print_multiplication_table*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "print_multiplication_table".} =
  if input == nil or length != 2: return -1
  let number = input[0]
  let terms = input[1]
  if number < -1_000_000 or number > 1_000_000 or terms < -20 or terms > 20: return -1
  var required = if terms > 0: int(terms - 1) else: 0
  var multiplier = 1'i64
  while multiplier <= terms:
    let product = number * multiplier
    required += decimalLength(number) + 3 + decimalLength(multiplier) + 3 + decimalLength(product)
    inc multiplier
  if outputCapacity < csize_t(required) or (required > 0 and output == nil): return -2
  var position = 0
  multiplier = 1
  while multiplier <= terms:
    if multiplier > 1:
      output[position] = uint8(ord('\n'))
      inc position
    appendDecimal(output, position, number)
    output[position] = uint8(ord(' '))
    output[position + 1] = uint8(ord('*'))
    output[position + 2] = uint8(ord(' '))
    position += 3
    appendDecimal(output, position, multiplier)
    output[position] = uint8(ord(' '))
    output[position + 1] = uint8(ord('='))
    output[position + 2] = uint8(ord(' '))
    position += 3
    appendDecimal(output, position, number * multiplier)
    inc multiplier
  int64(position)
