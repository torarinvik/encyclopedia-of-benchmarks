const
  Modulus = 998_244_353'i64
  MaxN = 8
  MaxInput = 11

type
  Points = array[MaxN, int64]
  Differences = array[MaxN, int64]
  NewtonCoefficients = array[MaxN, int64]
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

proc polynomial_interpolation_on_geometric_sequence*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "polynomial_interpolation_on_geometric_sequence".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  if nValue < 0 or nValue > MaxN.int64: return -1
  let n = nValue.int
  let a = input[1]
  let r = input[2]
  if length != csize_t(3 + n) or a < 0 or a >= Modulus or r < 0 or r >= Modulus: return -1

  var points: Points
  var differences: Differences
  var newton: NewtonCoefficients
  var point = a
  for i in 0 ..< n:
    points[i] = point
    differences[i] = input[3 + i]
    if differences[i] < 0 or differences[i] >= Modulus: return -1
    for j in 0 ..< i:
      if points[i] == points[j]: return -1
    point = point * r mod Modulus

  let bytes = 8 * n
  if output.isNil or capacity < csize_t(bytes): return -2
  if n == 0: return 0
  newton[0] = differences[0]
  for order in 1 ..< n:
    let rOrder = powerMod(r, order.int64)
    var endIndex = n
    while endIndex > order:
      dec endIndex
      let rFactor = powerMod(r, (endIndex - order).int64)
      var denominator = a * rFactor mod Modulus
      denominator = denominator * (rOrder - 1) mod Modulus
      let inverse = powerMod(normalize(denominator), Modulus - 2)
      differences[endIndex] = normalize((differences[endIndex] - differences[endIndex - 1]) * inverse)
    newton[order] = differences[order]

  var coefficients: ResultCoefficients
  var basis: BasisCoefficients
  basis[0] = 1
  var degree = 0
  for order in 0 ..< n:
    for k in 0 .. degree:
      coefficients[k] = (coefficients[k] + newton[order] * basis[k]) mod Modulus
    if order + 1 == n: break
    var expanded: BasisCoefficients
    for k in 0 .. degree:
      expanded[k] = normalize(expanded[k] - basis[k] * points[order])
      expanded[k + 1] = normalize(expanded[k + 1] + basis[k])
    for k in 0 .. degree + 1: basis[k] = expanded[k]
    inc degree
  for i in 0 ..< n: storeLe(output, 8 * i, coefficients[i])
  int64(bytes)
