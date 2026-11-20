const Modulus = 998244353'i64
const MaxInputLength = 11
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

proc nextNumerator(coefficient, rho: int64): int64 =
  coefficient * ((rho + 1) mod Modulus) mod Modulus

proc divisorsAreNonzero(input: I64Array, count: int): bool =
  var rho = 0'i64
  for index in 1 ..< count:
    let top = nextNumerator(input[index + 1], rho)
    let denominator = (1 + Modulus - top) mod Modulus
    if denominator == 0: return false
    rho = top * modPow(denominator, Modulus - 2) mod Modulus
  true

proc storeI64Le(output: ByteArray, offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc continued_fraction_forward_series_recurrence*(input: I64Array, length: csize_t,
    output: ByteArray, capacity: csize_t): int64
    {.cdecl, exportc: "continued_fraction_forward_series_recurrence".} =
  if input.isNil or length < 3 or length > csize_t(MaxInputLength): return -1
  let countValue = input[0]
  if countValue < 2 or countValue > 9: return -1
  let count = int(countValue)
  if length != csize_t(count + 1): return -1
  for index in 1 .. count:
    if input[index] < 0 or input[index] >= Modulus: return -1
  if not divisorsAreNonzero(input, count): return -1
  let required = 8 * (count + 1)
  if output.isNil or capacity < csize_t(required): return -2

  storeI64Le(output, 0, countValue)
  var rho = 0'i64
  var term = input[1]
  var total = term
  storeI64Le(output, 8, total)
  for index in 1 ..< count:
    let top = nextNumerator(input[index + 1], rho)
    let denominator = (1 + Modulus - top) mod Modulus
    rho = top * modPow(denominator, Modulus - 2) mod Modulus
    term = rho * term mod Modulus
    total = (total + term) mod Modulus
    storeI64Le(output, 8 * (index + 1), total)
  int64(required)
