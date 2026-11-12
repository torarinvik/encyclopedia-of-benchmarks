const MaxInput = 10000'i64

proc legendrePhi(primes: openArray[int64], value: int64, count: int): int64 =
  if value == 0: return 0
  if count == 0: return value
  if count == 1: return value - value div 2
  let prime = primes[count - 1]
  if value < prime: return 1
  return legendrePhi(primes, value, count - 1) -
    legendrePhi(primes, value div prime, count - 1)

proc legendre_prime_count*(value: int64): int64 {.cdecl, exportc: "legendre_prime_count".} =
  if value < 0 or value > MaxInput: return -1
  if value < 2: return 0
  var root = 0'i64
  while (root + 1) * (root + 1) <= value: inc root
  var composite: array[101, bool] = default(array[101, bool])
  var candidate = 2'i64
  while candidate * candidate <= root:
    if not composite[int(candidate)]:
      var multiple = candidate * candidate
      while multiple <= root:
        composite[int(multiple)] = true
        multiple += candidate
    inc candidate
  var primes: array[25, int64]
  var count = 0
  var candidate = 2'i64
  while candidate <= root:
    if not composite[int(candidate)]:
      primes[count] = candidate
      inc count
    inc candidate
  return legendrePhi(primes, value, count) + int64(count) - 1
