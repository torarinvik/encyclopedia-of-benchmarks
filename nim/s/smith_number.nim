proc isPrime(value: int64): bool =
  if value == 2: return true
  if value < 2 or value mod 2 == 0: return false
  var divisor = 3'i64
  while divisor <= value div divisor:
    if value mod divisor == 0: return false
    divisor += 2
  true

proc digitSum(valueArg: int64): int64 =
  var value = valueArg
  while value != 0:
    result += value mod 10
    value = value div 10

proc primeFactorDigitSum(value: int64): int64 =
  var remainder = value
  var factor = 2'i64
  while factor <= value div factor:
    while remainder mod factor == 0:
      result += digitSum(factor)
      remainder = remainder div factor
    inc factor
  if remainder > 1: result += digitSum(remainder)

proc smith_number*(value: int64): int64 {.cdecl, exportc: "smith_number".} =
  if value < 1 or value > 2147395599: return -1
  if isPrime(value): return 0
  if digitSum(value) == primeFactorDigitSum(value): 1 else: 0
