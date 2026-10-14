## Convert a most-significant-first bit array to radix 8 text.
proc binary_to_octal*(bits: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "binary_to_octal".} =
  if length == 0 or length > 63: return -1
  var value = 0'i64
  var index = csize_t(0)
  while index < length:
    let bit = bits[index]
    if bit < 0 or bit > 1: return -1
    value = value * 2 + bit
    inc index
  var width = csize_t(1)
  var remaining = value
  while remaining >= 8:
    remaining = remaining div 8
    inc width
  if output == nil or outputCapacity < width: return -2
  var position = width
  remaining = value
  while position > 0:
    dec position
    let digit = remaining mod 8
    if digit < 10:
      output[position] = uint8(ord('0') + int(digit))
    else:
      output[position] = uint8(ord('a') + int(digit) - 10)
    remaining = remaining div 8
  int64(width)
