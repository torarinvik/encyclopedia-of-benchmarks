proc problem77*(threshold: int64): int64 {.cdecl, exportc: "problem77".} =
  if threshold < 0 or threshold > 100_000: return -1
  var partitions: array[100, int64]
  partitions[0] = 1
  for prime in 2 ..< 100:
    var isPrime = true
    var divisor = 2
    while divisor * divisor <= prime:
      if prime mod divisor == 0:
        isPrime = false
        break
      divisor += 1
    if isPrime:
      for total in prime ..< 100: partitions[total] += partitions[total - prime]
  for value in 1 ..< 100:
    if partitions[value] > threshold: return value.int64
  -1
