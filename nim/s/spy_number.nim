## Return whether a positive integer's decimal digit sum equals its product.
proc spy_number*(input: int64): int64 {.cdecl, exportc: "spy_number".} =
  if input <= 0: return 0
  var number = input
  var digitSum = 0'i64
  var digitProduct = 1'i64
  while number > 0:
    let digit = number mod 10
    digitSum += digit
    digitProduct *= digit
    number = number div 10
  int64(digitSum == digitProduct)
