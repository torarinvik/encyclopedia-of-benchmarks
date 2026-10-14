## Convert a most-significant-first octal digit array to radix 16 text.
proc octal_to_hexadecimal*(digits: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "octal_to_hexadecimal".} =
  if length == 0 or length > 21: return -1
  var value = 0'i64
  var index = csize_t(0)
  while index < length:
    let octal_digit = digits[index]
    if octal_digit < 0 or octal_digit > 7: return -1
    value = value * 8 + octal_digit
    inc index
  var width = csize_t(1)
  var remaining = value
  while remaining >= 16:
    remaining = remaining div 16
    inc width
  if output == nil or outputCapacity < width: return -2
  var position = width
  remaining = value
  while position > 0:
    dec position
    let digit = remaining mod 16
    if digit < 10:
      output[position] = uint8(ord('0') + int(digit))
    else:
      output[position] = uint8(ord('a') + int(digit) - 10)
    remaining = remaining div 16
  int64(width)
