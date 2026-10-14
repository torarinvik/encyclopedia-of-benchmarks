## Fold most-significant-first digits in base 2 through 36 into i64.
proc any_base_to_decimal*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "any_base_to_decimal".} =
  if input == nil or length < 2 or length > 65: return -1
  let base = input[0]
  if base < 2 or base > 36: return -1
  var value: int64 = 0
  var index = csize_t(1)
  while index < length:
    let digit = input[index]
    if digit < 0 or digit >= base: return -1
    if value > (high(int64) - digit) div base: return -1
    value = value * base + digit
    inc index
  value
