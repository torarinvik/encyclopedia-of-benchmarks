## Count non-bouncy positive integers with at most the requested digits.
const MaxDigits = 100'i64

proc chooseInteger(n, r: int64): int64 =
  var resultValue = 1'i64
  for i in 1'i64 .. r:
    resultValue = resultValue * (n + 1 - i) div i
  resultValue

proc nonBouncyExact(digits: int64): int64 =
  chooseInteger(8 + digits, digits) + chooseInteger(9 + digits, digits) - 10

proc problem113*(numDigits: int64): int64 {.cdecl, exportc: "problem113".} =
  if numDigits > MaxDigits: return -1
  var total = 0'i64
  var digits = 1'i64
  while digits <= numDigits:
    total += nonBouncyExact(digits)
    inc digits
  total
