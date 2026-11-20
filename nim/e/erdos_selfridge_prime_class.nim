type
  I64Input = ptr UncheckedArray[int64]

const
  MaxPrime = 100_000'i64

proc esIsPrime(value: int64): bool =
  if value < 2: return false
  if value mod 2 == 0: return value == 2
  var divisor = 3'i64
  while divisor <= value div divisor:
    if value mod divisor == 0: return false
    divisor += 2
  true

proc esClassForPrime(prime, direction: int64): int64 =
  var remainder = prime + direction
  var best = 1'i64
  var divisor = 2'i64
  while divisor <= remainder div divisor:
    if remainder mod divisor == 0:
      if divisor > 3:
        best = max(best, 1 + esClassForPrime(divisor, direction))
      while remainder mod divisor == 0:
        remainder = remainder div divisor
    divisor += 1
  if remainder > 3:
    best = max(best, 1 + esClassForPrime(remainder, direction))
  best

proc erdos_selfridge_prime_class*(values: I64Input, length: csize_t): int64
    {.cdecl, exportc: "erdos_selfridge_prime_class".} =
  if values == nil or length < 1 or length > 3: return -1
  if length != 2: return -1
  let prime = values[0]
  let direction = values[1]
  if prime < 2 or prime > MaxPrime or (direction != -1 and direction != 1): return -1
  if not esIsPrime(prime): return -1
  esClassForPrime(prime, direction)

