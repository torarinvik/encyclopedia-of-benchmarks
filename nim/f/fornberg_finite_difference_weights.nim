const FornbergModulus = 998244353'i64
const FornbergMaxNodes = 8
const FornbergMaxInputLength = 12
type I64Array = ptr UncheckedArray[int64]
type ByteArray = ptr UncheckedArray[uint8]

proc fornbergModNorm(value: int64): int64 =
  let reduced = value mod FornbergModulus
  if reduced < 0: reduced + FornbergModulus else: reduced

proc fornbergModPow(baseValue, exponentValue: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod FornbergModulus
    base = base * base mod FornbergModulus
    exponent = exponent shr 1
  result

proc fornbergStoreI64Le(output: ByteArray, offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc fornberg_finite_difference_weights*(input: I64Array, length: csize_t,
    output: ByteArray, capacity: csize_t): int64
    {.cdecl, exportc: "fornberg_finite_difference_weights".} =
  if input.isNil or length < 4 or length > csize_t(FornbergMaxInputLength): return -1
  let nValue = input[0]
  let orderValue = input[1]
  let target = input[2]
  if nValue < 1 or nValue > int64(FornbergMaxNodes) or orderValue < 0 or orderValue > 3
      or orderValue >= nValue or length != csize_t(nValue + 3): return -1
  let n = int(nValue)
  if target < 0 or target >= FornbergModulus: return -1
  for index in 0 ..< n:
    let node = input[3 + index]
    if node < 0 or node >= FornbergModulus: return -1
    for previous in 0 ..< index:
      if node == input[3 + previous]: return -1

  var table: array[FornbergMaxNodes, array[4, int64]]
  table[0][0] = 1
  var previousProduct = 1'i64
  for newIndex in 1 ..< n:
    var oldLast: array[4, int64]
    for derivative in 0 ..< 4: oldLast[derivative] = table[newIndex - 1][derivative]
    var product = 1'i64
    let node = input[3 + newIndex]
    let factor = fornbergModNorm(node - target)
    let maxDerivative = min(newIndex, int(orderValue))
    for oldIndex in 0 ..< newIndex:
      let difference = fornbergModNorm(node - input[3 + oldIndex])
      product = product * difference mod FornbergModulus
      let inverseDifference = fornbergModPow(difference, FornbergModulus - 2)
      for derivative in countdown(maxDerivative, 0):
        let lower = if derivative == 0: 0'i64 else: table[oldIndex][derivative - 1]
        let numerator = fornbergModNorm(factor * table[oldIndex][derivative]
          - int64(derivative) * lower)
        table[oldIndex][derivative] = numerator * inverseDifference mod FornbergModulus
    let productInverse = fornbergModPow(product, FornbergModulus - 2)
    let lastFactor = fornbergModNorm(input[2 + newIndex] - target)
    for derivative in 0 .. maxDerivative:
      let lower = if derivative == 0: 0'i64 else: oldLast[derivative - 1]
      let numerator = fornbergModNorm(int64(derivative) * lower - lastFactor * oldLast[derivative])
      table[newIndex][derivative] = previousProduct * productInverse mod FornbergModulus
        * numerator mod FornbergModulus
    previousProduct = product

  let required = 8 * (n + 1)
  if output.isNil or capacity < csize_t(required): return -2
  fornbergStoreI64Le(output, 0, nValue)
  for index in 0 ..< n:
    fornbergStoreI64Le(output, 8 * (index + 1), table[index][int(orderValue)])
  int64(required)
