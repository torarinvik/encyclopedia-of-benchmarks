## Convert most-significant-first hexadecimal digits to a signed 64-bit value.
proc hexadecimal_to_decimal*(digits: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "hexadecimal_to_decimal".} =
  if length == 0 or length > 16: return -1
  if length == 16 and digits[0] > 7: return -1
  var result = 0'i64
  var index = csize_t(0)
  while index < length:
    let digit = digits[index]
    if digit < 0 or digit > 15: return -1
    result = result * 16 + digit
    inc index
  result
