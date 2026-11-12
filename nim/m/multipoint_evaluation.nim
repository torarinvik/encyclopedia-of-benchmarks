const
  Modulus = 998_244_353'i64
  MaxN = 8
  MaxM = 8
  LeafBase = 8
  NodeCapacity = 16
  CoefficientCapacity = 9
  MaxInput = 18

type
  Polynomial = array[CoefficientCapacity, int64]
  ProductTree = array[NodeCapacity, Polynomial]
  Lengths = array[NodeCapacity, int]

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc trim(polynomial: Polynomial, initialLength: int): int =
  result = initialLength
  while result > 1 and polynomial[result - 1] == 0: dec result

proc multiply(left: Polynomial, leftLength: int, right: Polynomial, rightLength: int,
              product: var Polynomial): int =
  result = leftLength + rightLength - 1
  for i in 0 ..< result: product[i] = 0
  for i in 0 ..< leftLength:
    for j in 0 ..< rightLength:
      product[i + j] = (product[i + j] + left[i] * right[j]) mod Modulus

proc remainder(dividend: Polynomial, dividendLength: int, divisor: Polynomial,
               divisorLength: int, output: var Polynomial): int =
  for i in 0 ..< CoefficientCapacity: output[i] = 0
  if divisorLength == 1 and divisor[0] == 1: return 1
  for i in 0 ..< dividendLength: output[i] = dividend[i]
  result = trim(output, dividendLength)
  while result >= divisorLength:
    let shift = result - divisorLength
    let factor = output[result - 1]
    for degree in 0 ..< divisorLength:
      let slot = shift + degree
      output[slot] = (output[slot] - factor * divisor[degree]) mod Modulus
      if output[slot] < 0: output[slot] += Modulus
    result = trim(output, result)

proc multipoint_evaluation*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "multipoint_evaluation".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 1 or nValue > MaxN.int64 or mValue < 1 or mValue > MaxM.int64: return -1
  let n = nValue.int
  let m = mValue.int
  if length != csize_t(2 + n + m): return -1
  for i in 0 ..< n + m:
    if input[i + 2] < 0 or input[i + 2] >= Modulus: return -1
  if input[n + 1] == 0: return -1
  let bytes = 8 * m
  if output.isNil or capacity < csize_t(bytes): return -2

  var products: ProductTree
  var remainders: ProductTree
  var productLengths, remainderLengths, starts, spans: Lengths
  for node in 1 ..< NodeCapacity:
    products[node][0] = 1
    productLengths[node] = 1
  for i in 0 ..< m:
    let leaf = LeafBase + i
    let point = input[2 + n + i]
    products[leaf][0] = if point == 0: 0 else: Modulus - point
    products[leaf][1] = 1
    productLengths[leaf] = 2
  for node in countdown(LeafBase - 1, 1):
    productLengths[node] = multiply(products[2 * node], productLengths[2 * node],
      products[2 * node + 1], productLengths[2 * node + 1], products[node])
  starts[1] = 0
  spans[1] = LeafBase
  for node in 1 ..< LeafBase:
    spans[2 * node] = spans[node] div 2
    spans[2 * node + 1] = spans[node] div 2
    starts[2 * node] = starts[node]
    starts[2 * node + 1] = starts[node] + spans[node] div 2
  var inputPolynomial: Polynomial
  for i in 0 ..< n: inputPolynomial[i] = input[i + 2]
  remainderLengths[1] = remainder(inputPolynomial, n, products[1], productLengths[1], remainders[1])
  for node in 1 ..< LeafBase:
    for side in 0 ..< 2:
      let child = 2 * node + side
      if starts[child] < m:
        remainderLengths[child] = remainder(remainders[node], remainderLengths[node],
          products[child], productLengths[child], remainders[child])
  for i in 0 ..< m: storeLe(output, 8 * i, remainders[LeafBase + i][0])
  int64(bytes)
