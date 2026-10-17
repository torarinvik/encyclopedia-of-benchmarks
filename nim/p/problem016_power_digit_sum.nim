const MaxDigits = 1001

proc problem016_power_digit_sum*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "problem016_power_digit_sum".} =
  if values.isNil or length != 2: return -1
  let base = values[0]
  let exponent = values[1]
  if base < 0 or base > 9 or exponent < 0 or exponent > 1000: return -1

  var digits: array[MaxDigits, int64]
  digits[0] = base
  var digitCount = 1

  var power = 1'i64
  while power < exponent:
    var carry = 0'i64
    for index in 0 ..< digitCount:
      let product = digits[index] * base + carry
      digits[index] = product mod 10
      carry = product div 10
    while carry > 0:
      if digitCount >= MaxDigits: return -1
      digits[digitCount] = carry mod 10
      inc digitCount
      carry = carry div 10
    inc power

  var sum = 0'i64
  for index in 0 ..< digitCount:
    sum += digits[index]
  sum
