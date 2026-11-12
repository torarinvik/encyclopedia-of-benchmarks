const
  Modulus = 998_244_353'i64
  MaxLength = 6
  MaxInput = 14
  Capacity = 16

type Poly = array[Capacity, int64]

proc powerMod(baseInput, exponentInput: int64): int64 =
  var base = baseInput
  var exponent = exponentInput
  var result = 1'i64
  while exponent > 0:
    if exponent mod 2 != 0: result = result * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent div 2
  result

proc trim(poly: Poly, lengthInput: int): int =
  var length = lengthInput
  while length > 0 and poly[length - 1] == 0: dec length
  length

proc dividePoly(dividend: Poly, dividendLength: int, divisor: Poly, divisorLength: int):
    tuple[quotient: Poly, quotientLength: int, remainder: Poly, remainderLength: int] =
  var quotient: Poly
  var remainder = dividend
  var remainderLength = trim(remainder, dividendLength)
  if remainderLength >= divisorLength:
    let inverseLead = powerMod(divisor[divisorLength - 1], Modulus - 2)
    while remainderLength >= divisorLength:
      let shift = remainderLength - divisorLength
      let factor = remainder[remainderLength - 1] * inverseLead mod Modulus
      quotient[shift] = factor
      for j in 0 ..< divisorLength:
        var value = (remainder[shift + j] - factor * divisor[j]) mod Modulus
        if value < 0: value += Modulus
        remainder[shift + j] = value
      remainderLength = trim(remainder, remainderLength)
  let quotientBound = if dividendLength >= divisorLength: dividendLength - divisorLength + 1 else: 0
  (quotient, trim(quotient, quotientBound), remainder, remainderLength)

proc multiply(left: Poly, leftLength: int, right: Poly, rightLength: int): tuple[poly: Poly, length: int] =
  var product: Poly
  if leftLength == 0 or rightLength == 0: return (product, 0)
  for i in 0 ..< leftLength:
    for j in 0 ..< rightLength:
      if i + j < Capacity:
        product[i + j] = (product[i + j] + left[i] * right[j]) mod Modulus
  let bound = min(Capacity, leftLength + rightLength - 1)
  (product, trim(product, bound))

proc subtract(left: Poly, leftLength: int, right: Poly, rightLength: int): tuple[poly: Poly, length: int] =
  var difference: Poly
  let bound = max(leftLength, rightLength)
  for i in 0 ..< bound:
    let a = if i < leftLength: left[i] else: 0'i64
    let b = if i < rightLength: right[i] else: 0'i64
    difference[i] = (a - b + Modulus) mod Modulus
  (difference, trim(difference, bound))

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc inv_of_polynomials*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "inv_of_polynomials".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 1 or nValue > MaxLength.int64 or mValue < 1 or mValue > MaxLength.int64: return -1
  let n = nValue.int
  let m = mValue.int
  if length != csize_t(2 + n + m): return -1
  var f, g: Poly
  for i in 0 ..< n:
    f[i] = input[2 + i]
    if f[i] < 0 or f[i] >= Modulus: return -1
  for i in 0 ..< m:
    g[i] = input[2 + n + i]
    if g[i] < 0 or g[i] >= Modulus: return -1
  if f[n - 1] == 0 or g[m - 1] == 0: return -1

  var inverse: Poly
  var inverseLength = 0
  if m > 1:
    let initial = dividePoly(f, n, g, m)
    var r0 = g
    var r0Length = m
    var r1 = initial.remainder
    var r1Length = initial.remainderLength
    var s0: Poly
    var s0Length = 0
    var s1: Poly
    s1[0] = 1
    var s1Length = 1
    while r1Length > 0:
      let division = dividePoly(r0, r0Length, r1, r1Length)
      let product = multiply(division.quotient, division.quotientLength, s1, s1Length)
      let nextS = subtract(s0, s0Length, product.poly, product.length)
      r0 = r1
      r0Length = r1Length
      r1 = division.remainder
      r1Length = division.remainderLength
      s0 = s1
      s0Length = s1Length
      s1 = nextS.poly
      s1Length = nextS.length
    if r0Length != 1: return -1
    let scale = powerMod(r0[0], Modulus - 2)
    for i in 0 ..< s0Length: inverse[i] = s0[i] * scale mod Modulus
    inverseLength = trim(inverse, s0Length)

  let bytes = 8 * inverseLength
  if output.isNil or capacity < csize_t(bytes): return -2
  for i in 0 ..< inverseLength: storeLe(output, 8 * i, inverse[i])
  int64(bytes)
