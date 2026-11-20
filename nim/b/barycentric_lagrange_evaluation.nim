const BaryModulus = 998244353'i64
const BaryMaxNodes = 8
const BaryMaxInputLength = 19
type I64Array = ptr UncheckedArray[int64]

proc baryModPow(baseValue, exponentValue: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod BaryModulus
    base = base * base mod BaryModulus
    exponent = exponent shr 1
  result

proc barycentric_lagrange_evaluation*(input: I64Array, length: csize_t): int64
    {.cdecl, exportc: "barycentric_lagrange_evaluation".} =
  if input.isNil or length < 4 or length > csize_t(BaryMaxInputLength): return -1
  let countValue = input[0]
  if countValue < 1 or countValue > int64(BaryMaxNodes): return -1
  let count = int(countValue)
  if length != csize_t(2 * count + 2): return -1
  for index in 1 ..< int(length):
    if input[index] < 0 or input[index] >= BaryModulus: return -1
  for left in 0 ..< count:
    for right in 0 ..< left:
      if input[1 + left] == input[1 + right]: return -1

  var weights: array[BaryMaxNodes, int64]
  for index in 0 ..< count:
    var product = 1'i64
    let node = input[1 + index]
    for other in 0 ..< count:
      if other == index: continue
      let difference = (node - input[1 + other] + BaryModulus) mod BaryModulus
      product = product * difference mod BaryModulus
    weights[index] = baryModPow(product, BaryModulus - 2)

  let ordinateStart = 1 + count
  let query = input[2 * count + 1]
  for index in 0 ..< count:
    if query == input[1 + index]: return input[ordinateStart + index]
  var numerator = 0'i64
  var denominator = 0'i64
  for index in 0 ..< count:
    let difference = (query - input[1 + index] + BaryModulus) mod BaryModulus
    let term = weights[index] * baryModPow(difference, BaryModulus - 2) mod BaryModulus
    numerator = (numerator + term * input[ordinateStart + index]) mod BaryModulus
    denominator = (denominator + term) mod BaryModulus
  if denominator == 0: return -1
  numerator * baryModPow(denominator, BaryModulus - 2) mod BaryModulus
