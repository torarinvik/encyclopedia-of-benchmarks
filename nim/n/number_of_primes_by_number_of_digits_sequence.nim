proc isPrime(value: int64): bool =
  if value < 2: return false
  var factor = 2'i64
  while factor <= value div factor:
    if value mod factor == 0: return false
    factor += 1
  return true

proc number_of_primes_by_number_of_digits_sequence*(index: int64): int64 {.cdecl, exportc: "number_of_primes_by_number_of_digits_sequence".} =
  if index < 0 or index > 3: return -1
  if index == 0: return 0
  var lower = 1'i64
  for _ in 1 ..< index: lower *= 10
  let upper = lower * 10
  var count = 0'i64
  for value in lower + 1 .. upper:
    if isPrime(value): count += 1
  return count
