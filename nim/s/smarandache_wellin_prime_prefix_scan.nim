proc smallPrime(value: uint64): bool =
  if value < 2'u64: return false
  var divisor = 2'u64
  while divisor <= value div divisor:
    if value mod divisor == 0: return false
    inc divisor
  true

proc multiplyMod(left, right, modulus: uint64): uint64 =
  (left * right) mod modulus

proc powerMod(initialBase, initialExponent, modulus: uint64): uint64 =
  var base = initialBase mod modulus
  var exponent = initialExponent
  var result = 1'u64
  while exponent != 0:
    if (exponent and 1) != 0: result = multiplyMod(result, base, modulus)
    exponent = exponent shr 1
    if exponent != 0: base = multiplyMod(base, base, modulus)
  result

proc primePrefix(value: uint64): bool =
  const smallPrimes = [2'u64, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]
  const bases = [2'u64, 7, 61]
  if value < 2: return false
  for prime in smallPrimes:
    if value == prime: return true
    if value mod prime == 0: return false
  var oddPart = value - 1
  var twos = 0
  while (oddPart and 1) == 0:
    oddPart = oddPart shr 1
    inc twos
  for base in bases:
    var witness = powerMod(base, oddPart, value)
    if witness == 1 or witness == value - 1: continue
    var round = 1
    while round < twos and witness != value - 1:
      witness = multiplyMod(witness, witness, value)
      inc round
    if witness != value - 1: return false
  true

proc smarandache_wellin_prime_prefix_scan*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input.isNil or length < 1 or length > 2: return -1
  let countWord = input[0]
  if countWord < 0 or countWord > 6 or length != 1: return -1

  var values: array[3, uint64]
  var resultCount = 0
  var prefix = 0'u64
  var candidate = 2'u64
  for _ in 0 ..< int(countWord):
    while not smallPrime(candidate):
      if candidate == 2: inc candidate else: candidate += 2
    var scale = 10'u64
    while scale <= candidate: scale *= 10
    prefix = prefix * scale + candidate
    if primePrefix(prefix):
      values[resultCount] = prefix
      inc resultCount
    if candidate == 2: inc candidate else: candidate += 2

  let byteCount = resultCount * 8
  if output.isNil or capacity < csize_t(byteCount): return -2
  var staged: array[24, uint8]
  for item in 0 ..< resultCount:
    for byte in 0 ..< 8:
      staged[item * 8 + byte] = uint8((values[item] shr (byte * 8)) and 255)
  for byte in 0 ..< byteCount: output[byte] = staged[byte]
  int64(byteCount)
