const
  MaxDegree = 4
  MaxPrime = 43'i64
  MaxExponent = 6
  MaxModulus = 100000'i64
  MaxLength = 10

proc normalizedMod(value, modulus: int64): int64 =
  result = value mod modulus
  if result < 0: result += modulus

proc isPrime(value: int64): bool =
  if value < 2: return false
  var divisor = 2'i64
  while divisor * divisor <= value:
    if value mod divisor == 0: return false
    inc divisor
  true

proc evaluate(input: ptr UncheckedArray[int64], degree: int,
              x, modulus: int64): int64 =
  var value = 0'i64
  var index = degree
  while index >= 0:
    value = normalizedMod(value * x + input[4 + index], modulus)
    dec index
  value

proc derivative(input: ptr UncheckedArray[int64], degree: int,
                x, prime: int64): int64 =
  var value = 0'i64
  var index = degree
  while index >= 1:
    value = normalizedMod(value * x + int64(index) * input[4 + index], prime)
    dec index
  value

proc hensel_lifting_polynomial_root*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "hensel_lifting_polynomial_root".} =
  if input == nil or length < 6 or length > csize_t(MaxLength): return -1
  let degreeValue = input[0]
  let prime = input[1]
  let exponent = input[2]
  let seed = input[3]
  if degreeValue < 1 or degreeValue > int64(MaxDegree) or prime < 2 or prime > MaxPrime: return -1
  if exponent < 1 or exponent > int64(MaxExponent) or seed < 0 or seed >= prime: return -1
  let degree = int(degreeValue)
  if int(length) != degree + 5 or not isPrime(prime): return -1
  for index in 0 .. degree:
    if input[4 + index] < -1000 or input[4 + index] > 1000: return -1

  var modulus = 1'i64
  for _ in 0 ..< int(exponent):
    if modulus > MaxModulus div prime: return -1
    modulus *= prime
  if evaluate(input, degree, seed, prime) != 0: return -1
  let derivativeValue = derivative(input, degree, seed, prime)
  if derivativeValue == 0: return -1
  var inverse = 0'i64
  for candidate in 1'i64 ..< prime:
    if derivativeValue * candidate mod prime == 1:
      inverse = candidate
      break
  if inverse == 0: return -1

  var root = seed
  var power = prime
  for _ in 1 ..< exponent:
    let nextPower = power * prime
    let residue = evaluate(input, degree, root, nextPower)
    let quotientDigit = residue div power
    let correction = normalizedMod(-quotientDigit * inverse, prime)
    root += correction * power
    power = nextPower
  root
