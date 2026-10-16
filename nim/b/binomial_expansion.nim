## Evaluate the bounded integer binomial expansion exactly.
const MaxExponent = 31
const InvalidResult = low(int64)

proc integerPower(base, exponent: int64): int64 =
  result = 1
  for _ in 0 ..< int(exponent):
    result *= base

proc binomialCoefficient(n, k: int64): int64 =
  var coefficients: array[MaxExponent + 1, int64]
  coefficients[0] = 1
  for row in 1 .. int(n):
    var column = min(row, int(k))
    while column > 0:
      coefficients[column] += coefficients[column - 1]
      dec column
  coefficients[int(k)]

proc binomial_expansion*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "binomial_expansion".} =
  if values.isNil or length != 3: return InvalidResult
  let a = values[0]
  let b = values[1]
  let exponent = values[2]
  if a < -2 or a > 2 or b < -2 or b > 2 or exponent < 0 or exponent > MaxExponent:
    return InvalidResult
  var answer: int64 = 0
  for index in 0 .. int(exponent):
    answer += binomialCoefficient(exponent, int64(index)) *
      integerPower(a, exponent - int64(index)) * integerPower(b, int64(index))
  answer
