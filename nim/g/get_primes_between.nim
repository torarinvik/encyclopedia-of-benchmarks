## Primes strictly between bounded prime endpoints, encoded as ASCII.
const MaxPrimeCount = 256

proc isPrimeCandidate(value: int64): bool =
  if value < 2: return false
  var divisor = 2'i64
  while divisor <= value div divisor:
    if value mod divisor == 0: return false
    inc divisor
  return true

proc decimalLength(value: int64): int =
  if value >= 100: return 3
  if value >= 10: return 2
  return 1

proc writeDecimal(output: ptr UncheckedArray[uint8], offset: var int, value: int64) =
  var remaining = value
  if remaining >= 100:
    output[offset] = uint8(ord('0') + int(remaining div 100))
    inc offset
    remaining = remaining mod 100
  if remaining >= 10:
    output[offset] = uint8(ord('0') + int(remaining div 10))
    inc offset
    remaining = remaining mod 10
  output[offset] = uint8(ord('0') + int(remaining))
  inc offset

proc get_primes_between*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "get_primes_between".} =
  if values == nil or length != 2: return -1
  let p1 = values[0]
  let p2 = values[1]
  if p1 < 2 or p1 > 997 or p2 < 2 or p2 > 997 or p1 >= p2:
    return -1
  if not isPrimeCandidate(p1) or not isPrimeCandidate(p2): return -1

  var primes: array[MaxPrimeCount, int64]
  var count = 0
  for candidate in (p1 + 1) ..< p2:
    if isPrimeCandidate(candidate):
      primes[count] = candidate
      inc count
  if count == 0: return -1

  var required = count - 1
  for index in 0 ..< count:
    required += decimalLength(primes[index])
  if output == nil or outputCapacity < csize_t(required): return -2

  var written = 0
  for index in 0 ..< count:
    if index != 0:
      output[written] = uint8(ord(','))
      inc written
    writeDecimal(output, written, primes[index])
  return int64(written)
