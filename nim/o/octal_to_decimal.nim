## Convert most-significant-first octal digits to a signed 64-bit value.
proc octal_to_decimal*(digits: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "octal_to_decimal".} =
  if length == 0 or length > 21: return -1
  var result = 0'i64
  var index = csize_t(0)
  while index < length:
    let digit = digits[index]
    if digit < 0 or digit > 7: return -1
    result = result * 8 + digit
    inc index
  result
