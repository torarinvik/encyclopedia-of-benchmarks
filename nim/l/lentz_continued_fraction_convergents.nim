const MaxTerms = 8
const MaxInputLength = 19
const Modulus = 998244353'i64

proc normalize(value: int64): int64 =
  let remainder = value mod Modulus
  if remainder < 0: remainder + Modulus else: remainder

proc power(baseInput, exponentInput: int64): int64 =
  var base = normalize(baseInput)
  var exponent = exponentInput
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent shr 1
  result

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc lentz_continued_fraction_convergents*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "lentz_continued_fraction_convergents".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength): return -1
  let countValue = input[0]
  if countValue < 1 or countValue > int64(MaxTerms): return -1
  let count = int(countValue)
  if length != csize_t(2 + 2 * count): return -1
  for i in 1 ..< int(length):
    if input[i] < 0 or input[i] >= Modulus: return -1
  var value = input[1]
  if value == 0: return -1
  var cRatio = value
  var dRatio = 0'i64
  var trace: array[MaxTerms + 2, int64]
  trace[0] = value
  for index in 0 ..< count:
    let numerator = input[2 + 2 * index]
    let denominator = input[3 + 2 * index]
    let dDenominator = normalize(denominator + numerator * dRatio)
    if dDenominator == 0 or cRatio == 0: return -1
    let cValue = normalize(denominator + numerator * power(cRatio, Modulus - 2))
    if cValue == 0: return -1
    dRatio = power(dDenominator, Modulus - 2)
    value = value * cValue mod Modulus * dRatio mod Modulus
    cRatio = cValue
    trace[index + 1] = value
  let outputBytes = 8 * (count + 2)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  storeI64Le(output, 0, int64(count + 1))
  for i in 0 .. count:
    storeI64Le(output, 8 * (i + 1), trace[i])
  int64(outputBytes)
