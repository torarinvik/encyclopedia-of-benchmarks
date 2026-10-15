proc isPrime(value: int64): bool =
  if value < 2: return false
  var factor = 2'i64
  while factor <= value div factor:
    if value mod factor == 0: return false
    factor += 1
  return true

proc kummer_numbers_sequence*(index: int64): int64 {.cdecl, exportc: "kummer_numbers_sequence".} =
  if index < 0 or index > 14: return -1
  var product = 1'i64
  var primeCount = 0'i64
  var candidate = 2'i64
  while primeCount < index + 1:
    if isPrime(candidate):
      product *= candidate
      primeCount += 1
    candidate += 1
  return product - 1
