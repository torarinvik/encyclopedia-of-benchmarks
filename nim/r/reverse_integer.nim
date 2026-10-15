## Reverse a signed 32-bit decimal integer, returning zero on overflow.
const InvalidResult = -2147483649'i64

proc reverse_integer*(inputValue: int64): int64 {.cdecl, exportc: "reverse_integer".} =
  if inputValue < -2147483648'i64 or inputValue > 2147483647'i64: return InvalidResult
  var input = inputValue
  var reversed = 0'i64
  while input != 0:
    let digit = input mod 10
    input = input div 10
    if reversed > 214748364 or (reversed == 214748364 and digit > 7): return 0
    if reversed < -214748364 or (reversed == -214748364 and digit < -8): return 0
    reversed = reversed * 10 + digit
  reversed
