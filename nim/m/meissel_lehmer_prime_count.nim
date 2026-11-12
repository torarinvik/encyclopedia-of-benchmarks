const
  MaxInput = 100_000_000'i64
  SieveLimit = 10_000
  MaxPrimes = 1_300
  PhiCacheX = 2_048
  PhiCacheS = 32

type PrimeCountContext = object
  composite: array[SieveLimit + 1, bool]
  primes: array[MaxPrimes, int32]
  primeCountPrefix: array[SieveLimit + 1, int32]
  phiCache: array[PhiCacheS + 1, array[PhiCacheX + 1, int32]]

proc integerSqrt(value: uint64): uint64 =
  var low = 0'u64
  var high = value + 1
  while low + 1 < high:
    let middle = low + (high - low) div 2
    if middle <= value div middle:
      low = middle
    else:
      high = middle
  low

proc integerCubeRoot(value: uint64): uint64 =
  var low = 0'u64
  var high = value + 1
  while low + 1 < high:
    let middle = low + (high - low) div 2
    if middle <= value div middle div middle:
      low = middle
    else:
      high = middle
  low

proc phi(context: var PrimeCountContext, value: uint64, primeCount: int): int64 =
  if value == 0:
    return 0
  if primeCount == 0:
    return int64(value)
  if primeCount == 1:
    return int64(value - value div 2)
  let prime = uint64(context.primes[primeCount - 1])
  if value < prime:
    return 1
  if value <= uint64(PhiCacheX) and primeCount <= PhiCacheS:
    let x = int(value)
    let cached = context.phiCache[primeCount][x]
    if cached != 0:
      return int64(cached)
    let result = phi(context, value, primeCount - 1) - phi(context, value div prime, primeCount - 1)
    context.phiCache[primeCount][x] = int32(result)
    return result
  phi(context, value, primeCount - 1) - phi(context, value div prime, primeCount - 1)

proc lehmerCount(context: var PrimeCountContext, value: uint64): int64 =
  if value <= uint64(SieveLimit):
    return int64(context.primeCountPrefix[int(value)])
  let a = int(context.primeCountPrefix[int(integerSqrt(integerSqrt(value)))])
  let b = int(context.primeCountPrefix[int(integerSqrt(value))])
  let c = int(context.primeCountPrefix[int(integerCubeRoot(value))])
  result = phi(context, value, a) + int64((b + a - 2) * (b - a + 1) div 2)
  for i in a ..< b:
    let quotient = value div uint64(context.primes[i])
    result -= lehmerCount(context, quotient)
    if i < c:
      let limit = int(lehmerCount(context, integerSqrt(quotient)))
      for j in i ..< limit:
        result -= lehmerCount(context, quotient div uint64(context.primes[j])) - int64(j)

proc meissel_lehmer_prime_count*(value: int64): int64 {.cdecl, exportc: "meissel_lehmer_prime_count".} =
  if value < 0 or value > MaxInput:
    return -1
  var context: PrimeCountContext
  for candidate in 2 .. SieveLimit:
    if context.composite[candidate]:
      continue
    if candidate <= SieveLimit div candidate:
      for multiple in countup(candidate * candidate, SieveLimit, candidate):
        context.composite[multiple] = true
  var primeCount = 0
  for candidate in 2 .. SieveLimit:
    if not context.composite[candidate]:
      context.primes[primeCount] = int32(candidate)
      inc primeCount
    context.primeCountPrefix[candidate] = context.primeCountPrefix[candidate - 1] +
      (if context.composite[candidate]: 0'i32 else: 1'i32)
  lehmerCount(context, uint64(value))
