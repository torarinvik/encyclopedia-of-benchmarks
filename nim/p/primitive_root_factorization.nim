const MaxPrime = 4093
const MaxInput = 2

proc isPrime(value: int64): bool =
  if value < 2: return false
  var divisor = 2'i64
  while divisor * divisor <= value:
    if value mod divisor == 0: return false
    inc divisor
  true

proc powerMod(baseInput, exponentInput, modulus: int64): int64 =
  var base = baseInput
  var exponent = exponentInput
  var answer = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: answer = answer * base mod modulus
    base = base * base mod modulus
    exponent = exponent shr 1
  answer

proc primitive_root_factorization*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "primitive_root_factorization".} =
  if input.isNil or length != 1 or length > MaxInput: return -1
  let prime = input[0]
  if prime < 2 or prime > MaxPrime or not isPrime(prime): return -1
  if prime == 2: return 1

  var factors: array[0..15, int64]
  var factorCount = 0
  var remaining = prime - 1
  var divisor = 2'i64
  while divisor * divisor <= remaining:
    if remaining mod divisor == 0:
      factors[factorCount] = divisor
      inc factorCount
      while remaining mod divisor == 0: remaining = remaining div divisor
    inc divisor
  if remaining > 1:
    factors[factorCount] = remaining
    inc factorCount

  for candidate in 2'i64 ..< prime:
    var valid = true
    for index in 0 ..< factorCount:
      if powerMod(candidate, (prime - 1) div factors[index], prime) == 1:
        valid = false
        break
    if valid: return candidate
  -1
