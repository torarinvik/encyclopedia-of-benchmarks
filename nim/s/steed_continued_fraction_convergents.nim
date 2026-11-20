const Modulus = 998244353'i64
const MaxInputLength = 19
type I64Array = ptr UncheckedArray[int64]
type ByteArray = ptr UncheckedArray[uint8]

proc modPow(baseValue, exponentValue: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent shr 1
  result

proc divisorsAreNonzero(input: I64Array, levels: int): bool =
  if input[2] == 0: return false
  var dValue = modPow(input[2], Modulus - 2)
  for level in 2 .. levels:
    let denominator = (dValue * input[2 * level + 1] + input[2 * level]) mod Modulus
    if denominator == 0: return false
    dValue = modPow(denominator, Modulus - 2)
  true

proc storeI64Le(output: ByteArray, offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc steed_continued_fraction_convergents*(input: I64Array, length: csize_t,
    output: ByteArray, capacity: csize_t): int64
    {.cdecl, exportc: "steed_continued_fraction_convergents".} =
  if input.isNil or length < 4 or length > csize_t(MaxInputLength): return -1
  let levelsValue = input[0]
  if levelsValue < 1 or levelsValue > 8: return -1
  let levels = int(levelsValue)
  if length != csize_t(2 + 2 * levels): return -1
  for index in 1 ..< int(length):
    if input[index] < 0 or input[index] >= Modulus: return -1
  if not divisorsAreNonzero(input, levels): return -1

  let required = 8 * (levels + 2)
  if output.isNil or capacity < csize_t(required): return -2
  storeI64Le(output, 0, levelsValue + 1)
  var current = input[1]
  storeI64Le(output, 8, current)
  var dValue = modPow(input[2], Modulus - 2)
  var delta = input[3] * dValue mod Modulus
  current = (current + delta) mod Modulus
  storeI64Le(output, 16, current)
  for level in 2 .. levels:
    let bValue = input[2 * level]
    let aValue = input[2 * level + 1]
    let denominator = (dValue * aValue + bValue) mod Modulus
    dValue = modPow(denominator, Modulus - 2)
    let factor = (bValue * dValue + Modulus - 1) mod Modulus
    delta = factor * delta mod Modulus
    current = (current + delta) mod Modulus
    storeI64Le(output, 8 * (level + 1), current)
  int64(required)
