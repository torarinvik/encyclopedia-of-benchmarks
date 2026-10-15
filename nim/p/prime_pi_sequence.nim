const MaxIndex = 999'i64

proc prime_pi_sequence*(index: int64): int64 {.cdecl, exportc: "prime_pi_sequence".} =
  if index < 0 or index > MaxIndex: return -1
  let target = index + 1
  var primes: array[168, int64]
  var primeCount = 0
  if target >= 2:
    primes[primeCount] = 2
    primeCount += 1
  var candidate = 3'i64
  while candidate <= target:
    var isPrime = true
    var i = 0
    while i < primeCount and isPrime:
      if candidate mod primes[i] == 0: isPrime = false
      i += 1
    if isPrime:
      primes[primeCount] = candidate
      primeCount += 1
    candidate += 2
  return int64(primeCount)
