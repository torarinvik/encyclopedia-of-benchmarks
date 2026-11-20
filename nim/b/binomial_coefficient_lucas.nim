proc isPrime(value: int64): bool =
  if value < 2: return false
  var divisor = 2'i64
  while divisor * divisor <= value:
    if value mod divisor == 0: return false
    inc divisor
  true

proc powerMod(base, exponent, modulus: int64): int64 =
  var factor = base mod modulus
  var remaining = exponent
  var result = 1'i64
  while remaining > 0:
    if remaining mod 2 == 1:
      result = (result * factor) mod modulus
    factor = (factor * factor) mod modulus
    remaining = remaining div 2
  result

proc binomial_coefficient_lucas*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "binomial_coefficient_lucas".} =
  if values == nil or length != 3: return -1
  let n = values[0]
  let k = values[1]
  let p = values[2]
  if n < 0 or k < 0 or k > n or p < 2 or p > 1009 or not isPrime(p):
    return -1

  var factorial: array[1010, int64]
  var inverseFactorial: array[1010, int64]
  factorial[0] = 1
  var i = 1'i64
  while i < p:
    factorial[int(i)] = (factorial[int(i - 1)] * i) mod p
    inc i

  inverseFactorial[int(p - 1)] = powerMod(factorial[int(p - 1)], p - 2, p)
  i = p - 1
  while i > 0:
    inverseFactorial[int(i - 1)] = (inverseFactorial[int(i)] * i) mod p
    dec i

  var remainingN = n
  var remainingK = k
  var result = 1'i64
  while remainingN > 0 or remainingK > 0:
    let digitN = remainingN mod p
    let digitK = remainingK mod p
    if digitK > digitN: return 0
    result = (result * factorial[int(digitN)]) mod p
    result = (result * inverseFactorial[int(digitK)]) mod p
    result = (result * inverseFactorial[int(digitN - digitK)]) mod p
    remainingN = remainingN div p
    remainingK = remainingK div p
  return result
