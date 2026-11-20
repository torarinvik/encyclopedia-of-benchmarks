const MaxParseableInputLength = 2

proc digit_factor(digit: int64): int64 =
  case digit
  of 0, 1: 1
  of 2: 2
  of 3: 6
  else: 4

proc two_power_mod_10(exponent_mod_four: int64): int64 =
  case exponent_mod_four
  of 0: 1
  of 1: 2
  of 2: 4
  else: 8

proc factorial_last_nonzero_digit*(input: ptr UncheckedArray[int64],
                                    length: csize_t): int64
    {.cdecl, exportc: "factorial_last_nonzero_digit".} =
  if input == nil or length < 1 or length > csize_t(MaxParseableInputLength):
    return -1
  if length != 1 or input[0] < 0:
    return -1

  var n = input[0]
  var result = 1'i64
  while n >= 5:
    let quotient = n div 5
    let remainder = n mod 5
    result = result * digit_factor(remainder) mod 10
    result = result * two_power_mod_10(quotient mod 4) mod 10
    n = quotient
  result * digit_factor(n) mod 10
