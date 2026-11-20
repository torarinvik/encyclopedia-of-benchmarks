type
  Factorization = object
    primes: array[16, int64]
    exponents: array[16, int64]
    count: int

const
  MinP = 3'i64
  MaxP = 1009'i64
  MaxParseableLength = 4

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
    if (exponent and 1) != 0: result = result * factor mod modulus
    factor = factor * factor mod modulus
    exponent = exponent shr 1
  result

proc factorize(inputValue: int64): Factorization =
  var value = inputValue
  var divisor = 2'i64
  while divisor * divisor <= value:
    if value mod divisor != 0:
      if divisor == 2: divisor = 3 else: divisor += 2
      continue
    var exponent = 0'i64
    while value mod divisor == 0:
      value = value div divisor
      inc exponent
    result.primes[result.count] = divisor
    result.exponents[result.count] = exponent
    inc result.count
    if divisor == 2: divisor = 3 else: divisor += 2
  if value > 1:
    result.primes[result.count] = value
    result.exponents[result.count] = 1
    inc result.count

proc primeOrderLog(generator, target, order, modulus: int64): int64 =
  var step = 1'i64
  while step * step < order: inc step
  var baby: array[64, int64]
  var value = 1'i64
  for j in 0 ..< int(step):
    baby[j] = value
    value = value * generator mod modulus
  let giantFactor = powMod(powMod(generator, step, modulus), modulus - 2, modulus)
  var probe = target
  for i in 0 .. int(step):
    for j in 0 ..< int(step):
      if baby[j] == probe:
        let candidate = int64(i) * step + int64(j)
        if candidate < order: return candidate
    probe = probe * giantFactor mod modulus
  -1

proc inverseMod(value, modulus: int64): int64 =
  var oldR = value
  var r = modulus
  var oldS = 1'i64
  var s = 0'i64
  while r != 0:
    let quotient = oldR div r
    let nextR = oldR - quotient * r
    let nextS = oldS - quotient * s
    oldR = r
    r = nextR
    oldS = s
    s = nextS
  if oldR != 1: return -1
  (oldS mod modulus + modulus) mod modulus

proc pohligHellman(p, base, target: int64): int64 =
  if target == 0: return -2
  let pFactors = factorize(p - 1)
  var order = p - 1
  for i in 0 ..< pFactors.count:
    let prime = pFactors.primes[i]
    while order mod prime == 0 and powMod(base, order div prime, p) == 1:
      order = order div prime
  if order == 1: return (if target == 1: 0 else: -2)

  let orderFactors = factorize(order)
  var solution = 0'i64
  var combinedModulus = 1'i64
  for i in 0 ..< orderFactors.count:
    let prime = orderFactors.primes[i]
    let exponent = orderFactors.exponents[i]
    var componentModulus = 1'i64
    for _ in 0 ..< int(exponent): componentModulus *= prime
    var partialLog = 0'i64
    var place = 1'i64
    let primeGenerator = powMod(base, order div prime, p)
    for _ in 0 ..< int(exponent):
      let currentPower = powMod(base, partialLog, p)
      let inverseCurrent = powMod(currentPower, p - 2, p)
      let residual = target * inverseCurrent mod p
      let digitTarget = powMod(residual, order div (place * prime), p)
      let digit = primeOrderLog(primeGenerator, digitTarget, prime, p)
      if digit < 0: return -2
      partialLog += digit * place
      place *= prime
    if combinedModulus == 1:
      solution = partialLog
      combinedModulus = componentModulus
    else:
      let inverse = inverseMod(combinedModulus mod componentModulus, componentModulus)
      if inverse < 0: return -2
      let difference = (partialLog - solution) mod componentModulus
      let adjustment = ((difference + componentModulus) mod componentModulus) * inverse mod componentModulus
      solution += combinedModulus * adjustment
      combinedModulus *= componentModulus
  solution = solution mod order
  if powMod(base, solution, p) == target: solution else: -2

proc verify(input: ptr UncheckedArray[int64], length: csize_t): int64 =
  if length != 3: return -1
  let p = input[0]
  let base = input[1]
  let target = input[2]
  if p < MinP or p > MaxP or not isPrime(p) or base < 1 or base >= p or target < 0 or target >= p:
    return -1
  pohligHellman(p, base, target)

proc pohlig_hellman_discrete_log*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "pohlig_hellman_discrete_log".} =
  if input == nil or length < 1 or length > csize_t(MaxParseableLength) or length != 3: return -1
  verify(input, length)
