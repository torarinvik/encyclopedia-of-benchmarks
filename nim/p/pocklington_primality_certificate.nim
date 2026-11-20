const
  MaxN = 65535'i64
  MaxFactors = 6'i64
  MaxExponent = 16'i64
  MaxLength = 22

proc gcdI64(leftValue, rightValue: int64): int64 =
  var left = leftValue
  var right = rightValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc isPrime(value: int64): bool =
  if value < 2: return false
  var divisor = 2'i64
  while divisor * divisor <= value:
    if value mod divisor == 0: return false
    if divisor == 2: divisor = 3 else: divisor += 2
  true

proc powMod(baseValue, exponentValue, modulus: int64): int64 =
  var result = 1'i64
  var factor = baseValue mod modulus
  var exponent = exponentValue
  while exponent > 0:
    if (exponent and 1) != 0: result = (result * factor) mod modulus
    factor = (factor * factor) mod modulus
    exponent = exponent shr 1
  result

proc verifyCertificate(input: ptr UncheckedArray[int64], length: csize_t): int64 =
  if length < 2 or length > csize_t(MaxLength): return -1
  let n = input[0]
  let count = input[1]
  if n < 3 or n > MaxN or count < 1 or count > MaxFactors: return -1
  if length != csize_t(3 + 3 * count): return -1

  var factoredPart = 1'i64
  var previousPrime = 1'i64
  var index = 0'i64
  while index < count:
    let offset = 2 + 3 * index
    let prime = input[offset]
    let exponent = input[offset + 1]
    let witness = input[offset + 2]
    if prime <= previousPrime or prime < 2 or exponent < 1 or exponent > MaxExponent:
      return -1
    if witness < 1 or witness >= n or not isPrime(prime): return -1
    previousPrime = prime
    var powerIndex = 0'i64
    while powerIndex < exponent:
      if factoredPart > (n - 1) div prime: return -1
      factoredPart *= prime
      inc powerIndex
    inc index

  let cofactor = input[2 + 3 * count]
  if cofactor < 1 or cofactor >= n or factoredPart * cofactor != n - 1: return -1
  if factoredPart * factoredPart <= n: return 0

  index = 0
  while index < count:
    let offset = 2 + 3 * index
    let prime = input[offset]
    let witness = input[offset + 2]
    if powMod(witness, n - 1, n) != 1: return 0
    let reduced = powMod(witness, (n - 1) div prime, n)
    let difference = (reduced + n - 1) mod n
    if gcdI64(difference, n) != 1: return 0
    inc index
  1

proc pocklington_primality_certificate*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "pocklington_primality_certificate".} =
  if input == nil or length < 2 or length > csize_t(MaxLength): return -1
  verifyCertificate(input, length)
