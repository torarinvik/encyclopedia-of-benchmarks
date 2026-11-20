const MaxPrime = 1009

proc pffIsPrime(value: int64): bool =
  if value < 2:
    return false
  var divisor = 2'i64
  while divisor <= value div divisor:
    if value mod divisor == 0:
      return false
    inc divisor
  true

proc prime_modulus_p_free_factorial*(input: ptr UncheckedArray[int64],
                                    length: csize_t): int64
    {.cdecl, exportc: "prime_modulus_p_free_factorial".} =
  if input.isNil or length != csize_t(2):
    return -1
  let n = input[0]
  let prime = input[1]
  if n < 0 or prime < 2 or prime > int64(MaxPrime):
    return -1
  if not pffIsPrime(prime):
    return -1

  let primeSize = int(prime)
  var factorial: array[MaxPrime, int64]
  factorial[0] = 1
  for value in 1 ..< primeSize:
    factorial[value] = factorial[value - 1] * int64(value) mod prime

  var answer = 1'i64
  var remaining = n
  while remaining > 0:
    let quotient = remaining div prime
    let residue = int(remaining mod prime)
    var block = factorial[residue]
    if quotient mod 2 != 0:
      block = (prime - block) mod prime
    answer = answer * block mod prime
    remaining = quotient
  answer
