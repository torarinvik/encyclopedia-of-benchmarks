## Expanding sieve strategy from the pinned Rust nth-prime routine.
proc nthprime*(nth: int64): int64 {.cdecl, exportc: "nthprime".} =
  if nth < 1 or nth > 100:
    return -1
  var primes: array[1600, uint64]
  var totalPrime = 0'u64
  var sizeFactor = 2'u64
  var size = uint64(nth) * sizeFactor

  while totalPrime < uint64(nth):
    if size > uint64(primes.len):
      return -1
    for index in 0 ..< int(size):
      primes[index] = 1
    for index in 2 ..< int(size):
      if primes[index] == 1:
        var multiple = index
        while multiple < int(size):
          let product = index * multiple
          if product < int(size):
            primes[product] = 0
          else:
            break
          inc multiple
    totalPrime = 0
    for index in 2 ..< int(size):
      totalPrime += primes[index]
    inc sizeFactor
    size = uint64(nth) * sizeFactor

  let usedSize = int(size - uint64(nth))
  var count = 0'u64
  for index in 2 ..< usedSize:
    count += primes[index]
    if count == uint64(nth):
      return int64(index)
  return -1
