## Generate zero-based prime terms using divisibility by all earlier primes.
proc primes_sequence*(index: int64): int64 {.cdecl, exportc: "primes_sequence".} =
  if index < 0 or index > 99: return -1
  var primes: array[100, int64]
  primes[0] = 2
  var count = 1'i64
  var candidate = 3'i64
  while count <= index:
    var isPrime = true
    for i in 0'i64 ..< count:
      if candidate mod primes[int(i)] == 0:
        isPrime = false
        break
    if isPrime:
      primes[int(count)] = candidate
      inc count
    candidate += 2
  return primes[int(index)]
