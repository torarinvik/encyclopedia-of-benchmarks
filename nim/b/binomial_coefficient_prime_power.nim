const
  BcpMaxQueries = 32
  BcpMaxN = 128
  BcpMaxParseable = 68
  BcpMaxModulus = 1_000_000_000'i64

proc bcpIsPrime(value: int64): bool =
  if value < 2: return false
  var divisor = 2'i64
  while divisor <= value div divisor:
    if value mod divisor == 0: return false
    inc divisor
  true

proc bcpPowMod(baseValue, exponentValue, modulus: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod modulus
    base = base * base mod modulus
    exponent = exponent shr 1
  result

proc binomial_coefficient_prime_power*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "binomial_coefficient_prime_power".} =
  if input.isNil or length < csize_t(3) or length > csize_t(BcpMaxParseable): return -1
  let p = input[0]
  let e = input[1]
  let qValue = input[2]
  if p < 2 or p > 31 or not bcpIsPrime(p) or e < 1 or e > 8 or qValue < 0 or qValue > BcpMaxQueries.int64: return -1
  var modulus = 1'i64
  for _ in 0 ..< int(e):
    modulus *= p
    if modulus > BcpMaxModulus: return -1
  let q = int(qValue)
  if int(length) != 3 + 2 * q: return -1
  for i in 0 ..< q:
    let n = input[3 + 2 * i]
    let k = input[4 + 2 * i]
    if n < 0 or n > BcpMaxN.int64 or k < 0 or k > n: return -1
  if q == 0: return 0
  let required = 4 * q
  if output.isNil or capacity < csize_t(required): return -2

  var unitPrefix: array[BcpMaxN + 1, int64]
  var pFreeFactorial: array[BcpMaxN + 1, int64]
  var valuation: array[BcpMaxN + 1, uint16]
  var residues: array[BcpMaxQueries, uint32]
  unitPrefix[0] = 1
  pFreeFactorial[0] = 1
  for n in 1 .. BcpMaxN:
    let factor = if n mod int(p) == 0: 1'i64 else: n.int64
    unitPrefix[n] = unitPrefix[n - 1] * factor mod modulus
    pFreeFactorial[n] = unitPrefix[n] * pFreeFactorial[n div int(p)] mod modulus
    valuation[n] = uint16(n div int(p) + int(valuation[n div int(p)]))
  let phi = modulus div p * (p - 1)
  for i in 0 ..< q:
    let n = int(input[3 + 2 * i])
    let k = int(input[4 + 2 * i])
    let pPower = int(valuation[n]) - int(valuation[k]) - int(valuation[n - k])
    if pPower < int(e):
      let denominator = pFreeFactorial[k] * pFreeFactorial[n - k] mod modulus
      let inverse = bcpPowMod(denominator, phi - 1, modulus)
      let primeFactor = bcpPowMod(p, pPower.int64, modulus)
      residues[i] = uint32(pFreeFactorial[n] * inverse mod modulus * primeFactor mod modulus)
  for i in 0 ..< q:
    for byte in 0 ..< 4:
      output[4 * i + byte] = uint8((residues[i] shr (8 * byte)) and 0xff'u32)
  required.int64
