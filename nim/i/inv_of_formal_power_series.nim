const
  Modulus = 998_244_353'i64
  MaxN = 64
  MaxInput = 66

proc powerMod(baseInput, exponentInput: int64): int64 =
  var base = baseInput
  var exponent = exponentInput
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent shr 1
  result

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc inv_of_formal_power_series*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "inv_of_formal_power_series".} =
  if input == nil or length < 2 or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  if int(length) != n + 1: return -1
  for i in 0 ..< n:
    if input[i + 1] < 0 or input[i + 1] >= Modulus: return -1
  if input[1] == 0: return -1
  let bytes = 8 * n
  if output == nil or int(capacity) < bytes: return -2

  var inverse: array[MaxN, int64]
  let inverseConstant = powerMod(input[1], Modulus - 2)
  inverse[0] = inverseConstant
  for degree in 1 ..< n:
    var sum = 0'i64
    for i in 1 .. degree: sum = (sum + input[i + 1] * inverse[degree - i]) mod Modulus
    inverse[degree] = (Modulus - inverseConstant * sum mod Modulus) mod Modulus
  for i in 0 ..< n: storeLe(output, 8 * i, inverse[i])
  int64(bytes)
