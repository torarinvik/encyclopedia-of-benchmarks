type I64Input = ptr UncheckedArray[int64]
const MaxParseableInputLength = 3
const InvalidResult = low(int64)

proc powLogarithmicValue(base: int64, exponent: int): int64 =
  if exponent == 0: return 1
  let half = powLogarithmicValue(base, exponent div 2)
  let square = half * half
  if exponent mod 2 == 0: return square
  square * base

proc pow_logarithmic*(input: I64Input, length: csize_t): int64
    {.cdecl, exportc: "pow_logarithmic".} =
  if input == nil or length < 2 or length > csize_t(MaxParseableInputLength): return InvalidResult
  if int(length) != 2: return InvalidResult
  let base = input[0]
  let exponent = input[1]
  if base < -10 or base > 10 or exponent < 0 or exponent > 15: return InvalidResult
  powLogarithmicValue(base, int(exponent))
