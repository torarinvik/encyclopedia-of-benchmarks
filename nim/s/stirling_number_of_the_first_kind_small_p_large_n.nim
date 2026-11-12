const
  MaxN = 1_000_000_000_000_000_000'i64
  MaxT = 8
  MaxK = 8
  Width = 9

proc isPrime(value: int64): bool =
  if value < 2: return false
  var divisor = 2'i64
  while divisor <= value div divisor:
    if value mod divisor == 0: return false
    inc divisor
  true

proc stirlingValue(n: int64, k: int, modulus: int64): int64 =
  let quotient = n div modulus
  let remainder = n mod modulus
  if quotient > k.int64: return 0
  let target = k - quotient.int
  var coefficients: array[Width, int64]
  coefficients[0] = 1
  for residue in 0'i64 ..< remainder:
    var degree = target
    while degree > 0:
      coefficients[degree] = (coefficients[degree - 1] - residue * coefficients[degree]) mod modulus
      if coefficients[degree] < 0: coefficients[degree] += modulus
      dec degree
    coefficients[0] = (-residue * coefficients[0]) mod modulus
    if coefficients[0] < 0: coefficients[0] += modulus
  let coefficient = coefficients[target]
  if quotient mod 2 == 0 or coefficient == 0: return coefficient
  modulus - coefficient

proc stirling_number_of_the_first_kind_small_p_large_n*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "stirling_number_of_the_first_kind_small_p_large_n".} =
  if input.isNil or length < csize_t(4) or length > csize_t(18): return -1
  let countValue = input[0]
  let modulus = input[1]
  if countValue < 1 or countValue > MaxT.int64: return -1
  if length != csize_t(2 + 2 * countValue): return -1
  if modulus < 11 or modulus > 97 or not isPrime(modulus): return -1

  var result = 0'i64
  for caseIndex in 0 ..< countValue.int:
    let n = input[2 + 2 * caseIndex]
    let kValue = input[3 + 2 * caseIndex]
    if n < 0 or n > MaxN or kValue < 0 or kValue > MaxK.int64 or kValue > n: return -1
    let value = stirlingValue(n, kValue.int, modulus)
    let next = (caseIndex + 1).int64
    result = (result + next * next * value) mod modulus
  result
