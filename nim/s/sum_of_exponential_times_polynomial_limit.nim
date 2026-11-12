## Infinite geometric-weighted power sum via an Eulerian polynomial row.
const Modulus = 998244353'i64
const MaxDegree = 256

proc sepplModPow(baseInput, exponentInput: int64): int64 =
  var base = baseInput
  var exponent = exponentInput
  result = 1
  while exponent > 0:
    if (exponent and 1) == 1: result = result * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent shr 1

proc sum_of_exponential_times_polynomial_limit*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "sum_of_exponential_times_polynomial_limit".} =
  if input == nil or length != 2: return -1
  let r = input[0]
  let degreeValue = input[1]
  if r < 0 or r >= Modulus or r == 1 or degreeValue < 0 or degreeValue > MaxDegree.int64: return -1
  let degree = int(degreeValue)
  let denominator = (1 - r + Modulus) mod Modulus
  let inverse = sepplModPow(denominator, Modulus - 2)
  if degree == 0: return inverse

  var row: array[MaxDegree + 1, int64]
  var nextRow: array[MaxDegree + 1, int64]
  row[0] = 1
  for n in 1..degree:
    for k in 0..n:
      var value = 0'i64
      if k > 0: value += int64(n - k) * row[k - 1]
      if k < n: value += int64(k + 1) * row[k]
      nextRow[k] = value mod Modulus
    for k in 0..n:
      row[k] = nextRow[k]
      nextRow[k] = 0

  var eulerianValue = 0'i64
  for k in countdown(degree, 1):
    eulerianValue = (eulerianValue * r + row[k - 1]) mod Modulus
  let denominatorPower = sepplModPow(inverse, int64(degree + 1))
  r * eulerianValue mod Modulus * denominatorPower mod Modulus
