const
  Modulus = 998_244_353'i64
  MaxN = 12
  MaxInput = 25

type
  ResultCoefficients = array[MaxN, int64]
  BasisCoefficients = array[MaxN + 1, int64]

proc normalize(value: int64): int64 =
  result = value mod Modulus
  if result < 0: result += Modulus

proc powerMod(baseValue, exponentValue: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  result = 1
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent shr 1

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc polynomial_interpolation*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "polynomial_interpolation".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN.int64: return -1
  let n = nValue.int
  if length != csize_t(1 + 2 * n): return -1
  for i in 0 ..< n:
    let xi = input[1 + i]
    let yi = input[1 + n + i]
    if xi < 0 or xi >= Modulus or yi < 0 or yi >= Modulus: return -1
    for j in 0 ..< i:
      if xi == input[1 + j]: return -1

  let bytes = 8 * n
  if output.isNil or capacity < csize_t(bytes): return -2
  var coefficients: ResultCoefficients
  for i in 0 ..< n:
    var basis: BasisCoefficients
    basis[0] = 1
    var degree = 0
    var denominator = 1'i64
    for j in 0 ..< n:
      if j == i: continue
      let xj = input[1 + j]
      denominator = denominator * (input[1 + i] - xj) mod Modulus
      var expanded: BasisCoefficients
      for k in 0 .. degree:
        expanded[k] = normalize(expanded[k] - basis[k] * xj)
        expanded[k + 1] = normalize(expanded[k + 1] + basis[k])
      for k in 0 .. degree + 1: basis[k] = expanded[k]
      inc degree
    let scale = input[1 + n + i] * powerMod(normalize(denominator), Modulus - 2) mod Modulus
    for k in 0 ..< n:
      coefficients[k] = (coefficients[k] + scale * basis[k]) mod Modulus
  for i in 0 ..< n: storeLe(output, 8 * i, coefficients[i])
  int64(bytes)
