const
  MaxT = 8
  MaxK = 1_000_000_000'i64
  MaxP = 1_000'i64

proc modularPower(baseInput, exponentInput, modulus: int64): int64 =
  var base = baseInput mod modulus
  var exponent = exponentInput
  result = 1 mod modulus
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod modulus
    base = base * base mod modulus
    exponent = exponent shr 1

proc isPrime(value: int64): bool =
  if value < 2: return false
  var divisor = 2'i64
  while divisor * divisor <= value:
    if value mod divisor == 0: return false
    inc divisor
  true

proc factorDistinct(valueInput: int64, factors: var array[16, int64]): int =
  var value = valueInput
  var divisor = 2'i64
  while divisor * divisor <= value:
    if value mod divisor == 0:
      factors[result] = divisor
      inc result
      while value mod divisor == 0: value = value div divisor
    inc divisor
  if value > 1:
    factors[result] = value
    inc result

proc primitiveRoot(prime: int64): int64 =
  if prime == 2: return 1
  let order = prime - 1
  var factors: array[16, int64]
  let count = factorDistinct(order, factors)
  for candidate in 2'i64 ..< prime:
    var index = 0
    while index < count and modularPower(candidate, order div factors[index], prime) != 1: inc index
    if index == count: return candidate
  -1

proc gcdI64(aInput, bInput: int64): int64 =
  var a = aInput
  var b = bInput
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  a

proc modularInverse(value, modulus: int64): int64 =
  var oldT = 0'i64
  var newT = 1'i64
  var oldR = modulus
  var newR = value mod modulus
  while newR != 0:
    let quotient = oldR div newR
    let nextT = oldT - quotient * newT
    let nextR = oldR - quotient * newR
    oldT = newT
    newT = nextT
    oldR = newR
    newR = nextR
  if oldT < 0: oldT += modulus
  oldT

proc kthRoot(exponent, residue, prime: int64): int64 =
  if exponent == 0: return (if residue == 1: 0 else: -1)
  if residue == 0: return 0
  let order = prime - 1
  let generator = primitiveRoot(prime)
  var power = 1'i64
  var discreteLog = -1'i64
  for candidate in 0'i64 ..< order:
    if power == residue:
      discreteLog = candidate
      break
    power = power * generator mod prime
  if discreteLog < 0: return -1
  let common = gcdI64(exponent, order)
  if discreteLog mod common != 0: return -1
  let reducedOrder = order div common
  var rootExponent = 0'i64
  if reducedOrder > 1:
    let inverse = modularInverse((exponent div common) mod reducedOrder, reducedOrder)
    rootExponent = (discreteLog div common) * inverse mod reducedOrder
  let root = modularPower(generator, rootExponent, prime)
  if modularPower(root, exponent, prime) == residue: root else: -1

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc kth_root_mod*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "kth_root_mod".} =
  if input.isNil or length < csize_t(4) or length > csize_t(1 + 3 * MaxT): return -1
  let testCount64 = input[0]
  if testCount64 < 1 or testCount64 > int64(MaxT): return -1
  let testCount = int(testCount64)
  if int(length) != 1 + 3 * testCount: return -1
  var triples: array[3 * MaxT, int64]
  for index in countup(0, 3 * testCount - 1, 3):
    let exponent = input[index + 1]
    let residue = input[index + 2]
    let prime = input[index + 3]
    if exponent < 0 or exponent > MaxK or prime < 2 or prime > MaxP or
        residue < 0 or residue >= prime or not isPrime(prime): return -1
    triples[index] = exponent
    triples[index + 1] = residue
    triples[index + 2] = prime
  let required = 8 * testCount
  if output.isNil or capacity < csize_t(required): return -2
  for test in 0 ..< testCount:
    putI64Le(output, 8 * test, kthRoot(triples[3 * test], triples[3 * test + 1], triples[3 * test + 2]))
  int64(required)
