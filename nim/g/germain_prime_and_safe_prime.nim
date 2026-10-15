const MaxNumber = 1_000_000'i64

proc isPrime(value: int64): bool =
  if value == 2: return true
  if value < 2 or value mod 2 == 0: return false
  var divisor = 3'i64
  while divisor <= value div divisor:
    if value mod divisor == 0: return false
    divisor += 2
  return true

proc germain_prime_and_safe_prime*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "germain_prime_and_safe_prime".} =
  if values.isNil or length != 2: return -1
  let number = values[0]
  let selector = values[1]
  if number < 1 or number > MaxNumber or selector < 0 or selector > 1: return -1
  if selector == 0:
    if isPrime(number) and isPrime(2 * number + 1): return 1
    return 0
  if (number - 1) mod 2 == 0 and isPrime(number) and isPrime((number - 1) div 2): return 1
  return 0
