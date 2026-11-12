const
  Modulus = 998244353'i64
  PrngModulus = 2147483647'i64
  MaxN = 8
  MaxInput = 10
  MaxProduct = 17

type Polynomial = object
  coefficients: array[MaxProduct, int64]
  degree: int

proc zeroPoly(): Polynomial =
  result.degree = -1

proc normalize(value: int64): int64 =
  result = value mod Modulus
  if result < 0: result += Modulus

proc powerMod(baseInput, exponentInput: int64): int64 =
  var base = baseInput
  var exponent = exponentInput
  result = 1
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent shr 1

proc trim(poly: var Polynomial) =
  while poly.degree >= 0 and poly.coefficients[poly.degree] == 0: dec poly.degree

proc polyMod(valueInput: Polynomial, divisor: Polynomial): Polynomial =
  var value = valueInput
  if divisor.degree <= 0 or value.degree < 0: return zeroPoly()
  let inverse = powerMod(divisor.coefficients[divisor.degree], Modulus - 2)
  while value.degree >= divisor.degree:
    let shift = value.degree - divisor.degree
    let factor = value.coefficients[value.degree] * inverse mod Modulus
    for i in 0 .. divisor.degree:
      value.coefficients[shift + i] = normalize(value.coefficients[shift + i] - factor * divisor.coefficients[i])
    trim(value)
  value

proc multiplyMod(left, right, modulusPoly: Polynomial): Polynomial =
  if left.degree < 0 or right.degree < 0: return zeroPoly()
  var product: array[MaxProduct, int64]
  for i in 0 .. left.degree:
    for j in 0 .. right.degree:
      product[i + j] = (product[i + j] + left.coefficients[i] * right.coefficients[j]) mod Modulus
  var expanded = zeroPoly()
  expanded.degree = left.degree + right.degree
  for i in 0 .. expanded.degree: expanded.coefficients[i] = product[i]
  trim(expanded)
  polyMod(expanded, modulusPoly)

proc polynomialPowerMod(baseInput: Polynomial, exponentInput: int64, modulusPoly: Polynomial): Polynomial =
  var base = polyMod(baseInput, modulusPoly)
  var exponent = exponentInput
  var answer = zeroPoly()
  answer.coefficients[0] = 1
  answer.degree = 0
  while exponent > 0:
    if (exponent and 1) != 0: answer = multiplyMod(answer, base, modulusPoly)
    base = multiplyMod(base, base, modulusPoly)
    exponent = exponent shr 1
  answer

proc polynomialGcd(leftInput, rightInput: Polynomial): Polynomial =
  var left = leftInput
  var right = rightInput
  while right.degree >= 0:
    let remainder = polyMod(left, right)
    left = right
    right = remainder
  if left.degree < 0: return left
  let inverse = powerMod(left.coefficients[left.degree], Modulus - 2)
  for i in 0 .. left.degree: left.coefficients[i] = left.coefficients[i] * inverse mod Modulus
  left

proc divideExact(valueInput, divisor: Polynomial): Polynomial =
  var value = valueInput
  var quotient = zeroPoly()
  quotient.degree = value.degree - divisor.degree
  if quotient.degree < 0: return quotient
  let inverse = powerMod(divisor.coefficients[divisor.degree], Modulus - 2)
  while value.degree >= divisor.degree:
    let shift = value.degree - divisor.degree
    let factor = value.coefficients[value.degree] * inverse mod Modulus
    quotient.coefficients[shift] = factor
    for i in 0 .. divisor.degree:
      value.coefficients[shift + i] = normalize(value.coefficients[shift + i] - factor * divisor.coefficients[i])
    trim(value)
  trim(quotient)
  quotient

proc splitWithAffine(poly: Polynomial, slope, offset: int64,
    first, second: var Polynomial): bool =
  var affine = zeroPoly()
  affine.coefficients[0] = offset
  affine.coefficients[1] = slope
  affine.degree = 1
  affine = polyMod(affine, poly)
  var powered = polynomialPowerMod(affine, (Modulus - 1) div 2, poly)
  if powered.degree < 0:
    powered.coefficients[0] = Modulus - 1
    powered.degree = 0
  else:
    powered.coefficients[0] = normalize(powered.coefficients[0] - 1)
  trim(powered)
  let part = polynomialGcd(poly, powered)
  if part.degree <= 0 or part.degree >= poly.degree: return false
  first = part
  second = divideExact(poly, part)
  true

proc collectRoots(poly: Polynomial, roots: var array[MaxN, int64],
    rootCount: var int, stateInput: int64) =
  if poly.degree == 1:
    roots[rootCount] = normalize(-poly.coefficients[0] * powerMod(poly.coefficients[1], Modulus - 2))
    inc rootCount
    return
  var state = stateInput
  var first, second: Polynomial
  for _ in 0 ..< 32:
    state = state * 48271 mod PrngModulus
    var slope = state mod Modulus
    if slope == 0: slope = 1
    state = state * 48271 mod PrngModulus
    let offset = state mod Modulus
    if splitWithAffine(poly, slope, offset, first, second):
      collectRoots(first, roots, rootCount, state)
      collectRoots(second, roots, rootCount, state + 1)
      return
  for offset in 0'i64 ..< Modulus:
    if splitWithAffine(poly, 1, offset, first, second):
      collectRoots(first, roots, rootCount, state)
      collectRoots(second, roots, rootCount, state + offset + 1)
      return

proc findRoots(poly: Polynomial, roots: var array[MaxN, int64]): int =
  if poly.degree <= 0: return 0
  var x = zeroPoly()
  x.coefficients[1] = 1
  x.degree = 1
  let xMod = polyMod(x, poly)
  var xToP = polynomialPowerMod(xMod, Modulus, poly)
  let largest = max(xToP.degree, xMod.degree)
  if largest >= 0:
    for i in 0 .. largest:
      let left = if i <= xToP.degree: xToP.coefficients[i] else: 0
      let right = if i <= xMod.degree: xMod.coefficients[i] else: 0
      xToP.coefficients[i] = normalize(left - right)
  xToP.degree = largest
  trim(xToP)
  let linearPart = polynomialGcd(poly, xToP)
  if linearPart.degree <= 0: return 0
  var seed = 1'i64
  for i in 0 .. poly.degree: seed = (seed * 31 + poly.coefficients[i]) mod (PrngModulus - 1) + 1
  var rootCount = 0
  collectRoots(linearPart, roots, rootCount, seed)
  for i in 0 ..< rootCount:
    for j in i + 1 ..< rootCount:
      if roots[j] < roots[i]: swap(roots[i], roots[j])
  rootCount

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc polynomial_root_finding*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "polynomial_root_finding".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let degreeValue = input[0]
  if degreeValue < 0 or degreeValue > MaxN.int64 or length != csize_t(degreeValue + 2): return -1
  var polynomial = zeroPoly()
  polynomial.degree = int(degreeValue)
  for i in 0 .. polynomial.degree:
    if input[i + 1] < 0 or input[i + 1] >= Modulus: return -1
    polynomial.coefficients[i] = input[i + 1]
  if polynomial.coefficients[polynomial.degree] == 0: return -1
  var roots: array[MaxN, int64]
  let rootCount = findRoots(polynomial, roots)
  let bytes = csize_t(8 * (rootCount + 1))
  if output.isNil or capacity < bytes: return -2
  storeLe(output, 0, int64(rootCount))
  for i in 0 ..< rootCount: storeLe(output, 8 * (i + 1), roots[i])
  int64(bytes)
