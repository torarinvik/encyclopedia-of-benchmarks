## Sieve through n, then emit ascending prime/exponent pairs as little-endian u32 values.
proc writeU32Le(value: uint32, output: ptr UncheckedArray[uint8], position: int) =
  for byte in 0 ..< 4:
    output[position + byte] = uint8((value shr (8 * byte)) and 255)

proc prime_factorization_sieve*(value: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "prime_factorization_sieve".} =
  if value < 1 or value > 1_000_005: return -1
  if value == 1: return 0
  let limit = int(value)
  var isPrime = newSeq[bool](limit + 1)
  for index in 2 .. limit: isPrime[index] = true
  var prime = 2
  while prime <= limit div prime:
    if isPrime[prime]:
      var multiple = prime * prime
      while multiple <= limit:
        isPrime[multiple] = false
        multiple += prime
    inc prime

  var primes, exponents: array[10, uint32]
  var count = 0
  var remaining = value
  for candidate in 2 .. limit:
    if remaining == 1: break
    if not isPrime[candidate]: continue
    var exponent = 0'u32
    while remaining mod int64(candidate) == 0:
      remaining = remaining div int64(candidate)
      inc exponent
    if exponent != 0:
      primes[count] = uint32(candidate)
      exponents[count] = exponent
      inc count
  let required = count * 8
  if output == nil or outputCapacity < csize_t(required): return -2
  for index in 0 ..< count:
    writeU32Le(primes[index], output, 8 * index)
    writeU32Le(exponents[index], output, 8 * index + 4)
  int64(required)
