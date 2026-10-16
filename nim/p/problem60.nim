const MaxPrimes = 1000
const TargetSize = 5
const PairCacheSize = MaxPrimes * MaxPrimes

proc isPrime(value: int64): bool =
  if value < 2: return false
  if value == 2 or value == 3: return true
  if value mod 2 == 0 or value mod 3 == 0: return false
  var divisor = 5'i64
  while divisor <= value div divisor:
    if value mod divisor == 0 or value mod (divisor + 2) == 0: return false
    divisor += 6
  true

proc concatenate(left, right: int64): int64 =
  var scale = 10'i64
  while scale <= right: scale *= 10
  left * scale + right

proc pairWorks(primes: ptr UncheckedArray[int64], cache: ptr UncheckedArray[uint8],
               leftIndex, rightIndex: int): bool =
  let key = leftIndex * MaxPrimes + rightIndex
  if cache[key] != 0: return cache[key] == 2
  let reverseKey = rightIndex * MaxPrimes + leftIndex
  if cache[reverseKey] != 0: return cache[reverseKey] == 2
  let left = primes[leftIndex]
  let right = primes[rightIndex]
  let result = isPrime(concatenate(left, right)) and isPrime(concatenate(right, left))
  let state = if result: 2'u8 else: 1'u8
  cache[key] = state
  cache[reverseKey] = state
  result

proc searchSet(primes: ptr UncheckedArray[int64], primeCount: int,
               cache: ptr UncheckedArray[uint8], chain: var array[TargetSize, int],
               depth, start: int, sum: int64): int64 =
  if depth == TargetSize: return sum
  for candidate in start ..< primeCount:
    var compatible = true
    for member in 0 ..< depth:
      if not pairWorks(primes, cache, candidate, chain[member]):
        compatible = false
        break
    if not compatible: continue
    chain[depth] = candidate
    let result = searchSet(primes, primeCount, cache, chain, depth + 1,
                           candidate + 1, sum + primes[candidate])
    if result != 0: return result
  0

proc problem60*(placeholder: int64): int64 {.cdecl, exportc: "problem60".} =
  if placeholder != 0: return -1
  var primes: array[MaxPrimes, int64]
  primes[0] = 3
  primes[1] = 7
  primes[2] = 13
  primes[3] = 19
  var primeCount = 4
  while primeCount < MaxPrimes:
    var candidate = primes[primeCount - 1] + 3
    while not isPrime(candidate): candidate += 3
    primes[primeCount] = candidate
    inc primeCount
  var cache: array[PairCacheSize, uint8]
  var chain: array[TargetSize, int]
  let primePtr = cast[ptr UncheckedArray[int64]](addr primes[0])
  let cachePtr = cast[ptr UncheckedArray[uint8]](addr cache[0])
  for start in 0 ..< primeCount:
    chain[0] = start
    let result = searchSet(primePtr, primeCount, cachePtr, chain, 1,
                           start + 1, primes[start])
    if result != 0: return result
  -1
