const
  MaxT = 16
  MaxN = 16
  MaxModulus = 31'i64
  MaxParseableInputLength = 36

proc isPrime(value: int64): bool =
  if value < 2: return false
  var divisor = 2'i64
  while divisor <= value div divisor:
    if value mod divisor == 0: return false
    inc divisor
  true

proc modularPower(baseValue: int64, exponentValue: int, modulus: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod modulus
    base = base * base mod modulus
    exponent = exponent shr 1
  result

proc q_binomial_coefficient_prime_mod*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "q_binomial_coefficient_prime_mod".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxParseableInputLength):
    return -1
  let countValue = input[0]
  let modulus = input[1]
  let qValue = input[2]
  if countValue < 1 or countValue > MaxT.int64 or modulus < 2
      or modulus > MaxModulus or not isPrime(modulus) or qValue < 0
      or qValue >= modulus:
    return -1
  let count = int(countValue)
  if length != csize_t(3 + 2 * count): return -1

  var maxN = 0
  for query in 0..<count:
    let nValue = input[3 + 2 * query]
    let kValue = input[4 + 2 * query]
    if nValue < 0 or nValue > MaxN.int64 or kValue < 0 or kValue > MaxN.int64
        or nValue >= modulus or kValue >= modulus:
      return -1
    maxN = max(maxN, int(nValue))
  if output.isNil or capacity < csize_t(count): return -2

  var table: array[MaxN + 1, array[MaxN + 1, int64]]
  table[0][0] = 1
  for n in 1..maxN:
    table[n][0] = 1
    for k in 1..n:
      let previousSame = if k < n: table[n - 1][k] else: 0
      let weight = modularPower(qValue, n - k, modulus)
      table[n][k] = (previousSame + weight * table[n - 1][k - 1]) mod modulus

  for query in 0..<count:
    let n = int(input[3 + 2 * query])
    let k = int(input[4 + 2 * query])
    output[query] = uint8(if k > n: 0 else: table[n][k])
  int64(count)
