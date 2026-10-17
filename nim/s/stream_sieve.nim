const MaxPrimes = 100

var primeCache: array[MaxPrimes, int32]
var primeCount = 0
var nextCandidate = 3'i32

proc isPrimeCandidate(candidate: int32): bool =
  for index in 0 ..< primeCount:
    let divisor = primeCache[index]
    if divisor > candidate div divisor:
      break
    if candidate mod divisor == 0:
      return false
  true

proc extendPrimeCache(requestedCount: int) =
  if primeCount == 0:
    primeCache[0] = 2
    primeCount = 1
  while primeCount < requestedCount:
    let candidate = nextCandidate
    inc nextCandidate
    if isPrimeCandidate(candidate):
      primeCache[primeCount] = candidate
      inc primeCount

proc stream_sieve*(numberOfPrimes: int64, output: ptr UncheckedArray[uint8],
                   outputCapacity: csize_t): int64
    {.cdecl, exportc: "stream_sieve".} =
  if numberOfPrimes < int64(low(int32)) or numberOfPrimes > MaxPrimes: return -1
  if numberOfPrimes <= 0: return 0
  let count = int(numberOfPrimes)
  let required = csize_t(count * 4)
  if output == nil or outputCapacity < required: return -2

  extendPrimeCache(count)
  for index in 0 ..< count:
    let bits = cast[uint32](primeCache[index])
    for byte in 0 ..< 4:
      output[index * 4 + byte] = uint8((bits shr (8 * byte)) and 255)
  int64(required)
