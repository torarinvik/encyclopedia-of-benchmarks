const
  Field = 7
  MaxN = 7
  MaxPolynomial = 16
  MaxInputLength = 11

type
  Polynomial = object
    coefficients: array[MaxPolynomial, int]
    length: int
  DivisionResult = object
    quotient: Polynomial
    remainder: Polynomial
    valid: bool

proc normalize(value: int): int =
  let remainder = value mod Field
  if remainder < 0: remainder + Field else: remainder

proc zeroPolynomial(): Polynomial =
  result.length = 1

proc constantPolynomial(value: int): Polynomial =
  result = zeroPolynomial()
  result.coefficients[0] = normalize(value)

proc trim(polynomial: var Polynomial) =
  while polynomial.length > 1 and polynomial.coefficients[polynomial.length - 1] == 0:
    dec polynomial.length

proc isZero(polynomial: Polynomial): bool =
  polynomial.length == 1 and polynomial.coefficients[0] == 0

proc multiplyLinear(polynomial: Polynomial, root: int): Polynomial =
  result = zeroPolynomial()
  result.length = polynomial.length + 1
  for degree in 0 ..< polynomial.length:
    result.coefficients[degree] = normalize(result.coefficients[degree] - root * polynomial.coefficients[degree])
    result.coefficients[degree + 1] = normalize(result.coefficients[degree + 1] + polynomial.coefficients[degree])
  trim(result)

proc addScaled(target, source: Polynomial, scale: int): Polynomial =
  result = target
  result.length = max(result.length, source.length)
  for degree in 0 ..< source.length:
    result.coefficients[degree] = normalize(result.coefficients[degree] + scale * source.coefficients[degree])
  trim(result)

proc multiply(left, right: Polynomial): Polynomial =
  result = zeroPolynomial()
  result.length = left.length + right.length - 1
  for i in 0 ..< left.length:
    for j in 0 ..< right.length:
      result.coefficients[i + j] = normalize(result.coefficients[i + j] + left.coefficients[i] * right.coefficients[j])
  trim(result)

proc divideWithRemainder(numerator, denominator: Polynomial): DivisionResult =
  let inverse = [0, 1, 4, 5, 2, 3, 6]
  if isZero(denominator):
    result.valid = false
    return
  result.quotient = zeroPolynomial()
  result.remainder = numerator
  var divisor = denominator
  trim(result.remainder)
  trim(divisor)
  let inverseLead = inverse[divisor.coefficients[divisor.length - 1]]
  while not isZero(result.remainder) and result.remainder.length >= divisor.length:
    let shift = result.remainder.length - divisor.length
    let factor = normalize(result.remainder.coefficients[result.remainder.length - 1] * inverseLead)
    if result.quotient.length < shift + 1: result.quotient.length = shift + 1
    result.quotient.coefficients[shift] = normalize(result.quotient.coefficients[shift] + factor)
    for degree in 0 ..< divisor.length:
      result.remainder.coefficients[shift + degree] = normalize(
        result.remainder.coefficients[shift + degree] - factor * divisor.coefficients[degree])
    trim(result.remainder)
  trim(result.quotient)
  result.valid = true

proc interpolate(n: int, received: array[MaxN, int]): tuple[vanishing, interpolant: Polynomial] =
  let inverse = [0, 1, 4, 5, 2, 3, 6]
  result.vanishing = constantPolynomial(1)
  for point in 0 ..< n:
    result.vanishing = multiplyLinear(result.vanishing, point)

  result.interpolant = zeroPolynomial()
  for i in 0 ..< n:
    var basis = constantPolynomial(1)
    var denominator = 1
    for j in 0 ..< n:
      if i == j: continue
      basis = multiplyLinear(basis, j)
      denominator = normalize(denominator * (i - j))
    let scale = normalize(received[i] * inverse[denominator])
    result.interpolant = addScaled(result.interpolant, basis, scale)

proc decode(n, k, errorLimit: int, received: array[MaxN, int]): int64 =
  let (vanishing, interpolant) = interpolate(n, received)
  if isZero(interpolant): return 1

  var remainderPrevious = vanishing
  var remainderCurrent = interpolant
  var bezoutPrevious = zeroPolynomial()
  var bezoutCurrent = constantPolynomial(1)
  let threshold = (n + k - 1) div 2
  while not isZero(remainderCurrent) and remainderCurrent.length - 1 > threshold:
    let division = divideWithRemainder(remainderPrevious, remainderCurrent)
    if not division.valid: return 0
    let bezoutNext = addScaled(bezoutPrevious, multiply(division.quotient, bezoutCurrent), -1)
    remainderPrevious = remainderCurrent
    remainderCurrent = division.remainder
    bezoutPrevious = bezoutCurrent
    bezoutCurrent = bezoutNext
  if isZero(remainderCurrent) or isZero(bezoutCurrent): return 0

  let division = divideWithRemainder(remainderCurrent, bezoutCurrent)
  if not division.valid or not isZero(division.remainder): return 0
  var message = division.quotient
  trim(message)
  if message.length > k: return 0

  var mismatches = 0
  for x in 0 ..< n:
    var value = 0
    for degree in countdown(message.length - 1, 0):
      value = (value * x + message.coefficients[degree]) mod Field
    if value != received[x]: inc mismatches
  if mismatches > errorLimit: return 0

  var encoded = 1'i64
  var place = 1'i64
  for degree in 0 ..< k:
    if degree < message.length: encoded += int64(message.coefficients[degree]) * place
    place *= int64(Field)
  encoded

proc gao_rs_decode*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "gao_rs_decode".} =
  if input.isNil or length < 3 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let kValue = input[1]
  let errorValue = input[2]
  if nValue < 2 or nValue > int64(MaxN) or kValue < 1 or kValue > 3
      or kValue > nValue or errorValue < 0 or errorValue > 2: return -1
  let n, k, errorLimit = int(nValue), int(kValue), int(errorValue)
  if 2 * errorLimit > n - k or length != csize_t(3 + n): return -1

  var received: array[MaxN, int]
  for index in 0 ..< n:
    let symbol = input[3 + index]
    if symbol < 0 or symbol >= int64(Field): return -1
    received[index] = int(symbol)
  decode(n, k, errorLimit, received)
