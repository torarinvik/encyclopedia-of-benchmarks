proc isPrime(value: int64): bool =
  if value < 2: return false
  var factor = 2'i64
  while factor <= value div factor:
    if value mod factor == 0: return false
    factor += 1
  return true

proc number_of_primes_by_powers_of10_sequence*(index: int64): int64 {.cdecl, exportc: "number_of_primes_by_powers_of10_sequence".} =
  if index < 0 or index > 3: return -1
  if index == 0: return 0
  var upper = 10'i64
  var i = 1'i64
  while i < index:
    upper *= 10
    i += 1
  var count = 0'i64
  var value = 2'i64
  while value < upper:
    if isPrime(value): count += 1
    value += 1
  return count
