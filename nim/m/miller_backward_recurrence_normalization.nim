const MillerModulus = 998244353'i64
const MillerMaxInputLength = 35
type I64Array = ptr UncheckedArray[int64]
type ByteArray = ptr UncheckedArray[uint8]

proc millerModPow(baseValue, exponentValue: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod MillerModulus
    base = base * base mod MillerModulus
    exponent = exponent shr 1
  result

proc millerStoreI64Le(output: ByteArray, offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc miller_backward_recurrence_normalization*(input: I64Array, length: csize_t,
    output: ByteArray, capacity: csize_t): int64
    {.cdecl, exportc: "miller_backward_recurrence_normalization".} =
  if input.isNil or length < 6 or length > csize_t(MillerMaxInputLength): return -1
  let levelsValue = input[0]
  if levelsValue < 1 or levelsValue > 8: return -1
  let levels = int(levelsValue)
  if length != csize_t(4 * levels + 2): return -1
  for index in 1 ..< int(length):
    if input[index] < 0 or input[index] >= MillerModulus: return -1
  for level in 1 .. levels:
    if input[3 * level] == 0: return -1

  var trial: array[10, int64]
  for index in 0 ..< trial.len: trial[index] = 0
  trial[levels] = 1
  trial[levels + 1] = 0
  for level in countdown(levels, 1):
    let aValue = input[3 * level - 2]
    let bValue = input[3 * level - 1]
    let cValue = input[3 * level]
    let positive = bValue * trial[level] mod MillerModulus
    let negative = aValue * trial[level + 1] mod MillerModulus
    let numerator = (positive + MillerModulus - negative) mod MillerModulus
    trial[level - 1] = numerator * millerModPow(cValue, MillerModulus - 2) mod MillerModulus
  let lambdaStart = 3 * levels + 1
  var normalizer = 0'i64
  for index in 0 .. levels:
    normalizer = (normalizer + input[lambdaStart + index] * trial[index]) mod MillerModulus
  if normalizer == 0: return -1
  let scale = millerModPow(normalizer, MillerModulus - 2)
  let required = 8 * (levels + 2)
  if output.isNil or capacity < csize_t(required): return -2

  millerStoreI64Le(output, 0, levelsValue)
  for index in 0 .. levels:
    millerStoreI64Le(output, 8 * (index + 1), trial[index] * scale mod MillerModulus)
  int64(required)
