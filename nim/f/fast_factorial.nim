## Prime-exponent factorial using binary buckets and balanced powers.
const MaxN = 20
const MaxBuckets = 8

proc exponentInFactorial(prime, n: int64): int64 =
  var exponent = 0'i64
  var quotient = n div prime
  while quotient > 0:
    exponent += quotient
    quotient = quotient div prime
  exponent

proc powerBySquaring(base: int64, exponent: uint32): int64 =
  var resultValue = 1'i64
  var factor = base
  var remaining = exponent
  while remaining > 0:
    if (remaining and 1'u32) != 0: resultValue *= factor
    remaining = remaining shr 1
    if remaining > 0: factor *= factor
  resultValue

proc fast_factorial*(n: int64): int64 {.cdecl, exportc: "fast_factorial".} =
  if n < 0 or n > int64(MaxN): return -1
  if n < 2: return 1

  var isPrime: array[MaxN + 1, bool]
  for candidate in 2 .. int(n): isPrime[candidate] = true
  var prime = 2
  while prime * prime <= int(n):
    if isPrime[prime]:
      var multiple = prime * prime
      while multiple <= int(n):
        isPrime[multiple] = false
        multiple += prime
    inc prime

  let exponentOfTwo = exponentInFactorial(2, n)
  var nextPowerOfTwo = 1'i64
  var powerLog2 = 0'u32
  while nextPowerOfTwo < exponentOfTwo:
    nextPowerOfTwo *= 2
    inc powerLog2
  let bucketCount = int(powerLog2 + 1)
  var buckets: array[MaxBuckets, int64]
  for bit in 0 ..< MaxBuckets: buckets[bit] = 1

  for candidate in 2 .. int(n):
    if not isPrime[candidate]: continue
    let exponentBits = uint32(exponentInFactorial(int64(candidate), n))
    var mask = 1'u32
    for bit in 0 ..< bucketCount:
      if (exponentBits and mask) != 0: buckets[bit] *= int64(candidate)
      mask = mask shl 1

  var resultValue = 1'i64
  var powerExponent = 1'u32
  for bit in 0 ..< bucketCount:
    resultValue *= powerBySquaring(buckets[bit], powerExponent)
    powerExponent = powerExponent shl 1
  resultValue
