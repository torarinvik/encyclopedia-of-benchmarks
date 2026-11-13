const Stage1Primes: array[11, int64] = [2'i64, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31]
const MaxNumber = 10_000'i64
const MaxBound = 32'i64

proc modNorm(valueInput, modulus: int64): int64 =
  var value = valueInput mod modulus
  if value < 0: value += modulus
  value

proc gcdI64(leftInput, rightInput: int64): int64 =
  var left = abs(leftInput)
  var right = abs(rightInput)
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc squareFree(number: int64): bool =
  var divisor = 2'i64
  while divisor * divisor <= number:
    if number mod (divisor * divisor) == 0: return false
    inc divisor
  true

type XPoint = tuple[x, z: int64]

proc xDouble(point: XPoint, a24, modulus: int64): XPoint =
  let plus = modNorm(point.x + point.z, modulus)
  let minus = modNorm(point.x - point.z, modulus)
  let plusSq = plus * plus mod modulus
  let minusSq = minus * minus mod modulus
  let delta = modNorm(plusSq - minusSq, modulus)
  (plusSq * minusSq mod modulus,
   delta * modNorm(minusSq + a24 * delta, modulus) mod modulus)

proc xAdd(left, right, difference: XPoint, modulus: int64): XPoint =
  let first = modNorm(left.x - left.z, modulus) * modNorm(right.x + right.z, modulus) mod modulus
  let second = modNorm(left.x + left.z, modulus) * modNorm(right.x - right.z, modulus) mod modulus
  let sumTerm = modNorm(first + second, modulus)
  let differenceTerm = modNorm(first - second, modulus)
  (difference.z * sumTerm mod modulus * sumTerm mod modulus,
   difference.x * differenceTerm mod modulus * differenceTerm mod modulus)

proc xMultiply(point: XPoint, scalarInput, a24, modulus: int64): XPoint =
  var r0: XPoint = (1, 0)
  var r1 = point
  var copy = scalarInput
  var highest = 0
  while copy > 1:
    copy = copy shr 1
    inc highest
  var bit = highest
  while bit >= 0:
    if (scalarInput and (1'i64 shl bit)) != 0:
      r0 = xAdd(r0, r1, point, modulus)
      r1 = xDouble(r1, a24, modulus)
    else:
      r1 = xAdd(r0, r1, point, modulus)
      r0 = xDouble(r0, a24, modulus)
    dec bit
  r0

proc elliptic_curve_method_stage1*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "elliptic_curve_method_stage1".} =
  if input == nil or length != 5: return -1
  let number = input[0]
  let curveA = input[1]
  let pointX = input[2]
  let pointY = input[3]
  let bound = input[4]
  if number < 3 or number > MaxNumber or (number and 1) == 0 or bound < 2 or bound > MaxBound:
    return -1
  if curveA < 0 or curveA >= number or pointX < 0 or pointX >= number or pointY < 0 or pointY >= number:
    return -1
  if not squareFree(number) or gcdI64(curveA * curveA - 4, number) != 1: return -1
  let xSq = pointX * pointX mod number
  let rhs = (xSq * pointX + curveA * xSq + pointX) mod number
  if pointY * pointY mod number != rhs: return -1
  let inverseFour = if number mod 4 == 3: (number + 1) div 4 else (3 * number + 1) div 4
  let a24 = (curveA + 2) * inverseFour mod number
  var point: XPoint = (pointX, 1)
  for prime in Stage1Primes:
    if prime > bound: break
    var primePower = prime
    while primePower <= bound div prime: primePower *= prime
    point = xMultiply(point, primePower, a24, number)
    let divisor = gcdI64(point.z, number)
    if divisor > 1:
      if divisor < number: return 1
      return 0
  0
