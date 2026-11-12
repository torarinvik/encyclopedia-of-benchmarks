const
  Modulus = 998_244_353'i64
  MinN = 2
  MaxN = 16
  MaxInput = 18

proc modPower(baseValue, exponentValue: int64): int64 =
  var base = baseValue mod Modulus
  var exponent = exponentValue
  var result = 1'i64
  while exponent > 0:
    if exponent mod 2 != 0: result = result * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent div 2
  result

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc compositional_inverse_of_formal_power_series*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "compositional_inverse_of_formal_power_series".} =
  if input == nil or length < csize_t(MinN + 1) or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  if nValue < MinN or nValue > MaxN: return -1
  let n = int(nValue)
  if int(length) != n + 1: return -1
  for i in 0 ..< n:
    if input[i + 1] < 0 or input[i + 1] >= Modulus: return -1
  if input[1] != 0 or input[2] == 0: return -1
  let bytes = 8 * n
  if output == nil or int(capacity) < bytes: return -2

  var powers: array[MaxN * MaxN, int64]
  var inverseSeries: array[MaxN, int64]
  let inverseLinear = modPower(input[2], Modulus - 2)
  inverseSeries[1] = inverseLinear
  powers[MaxN + 1] = inverseLinear
  for degree in 2 ..< n:
    for power in 2 .. degree:
      var coefficient = 0'i64
      for split in 1 ..< degree:
        coefficient = (coefficient + powers[(power - 1) * MaxN + degree - split] *
          inverseSeries[split]) mod Modulus
      powers[power * MaxN + degree] = coefficient
    var composedCoefficient = 0'i64
    for power in 2 .. degree:
      composedCoefficient = (composedCoefficient + input[power + 1] *
        powers[power * MaxN + degree]) mod Modulus
    inverseSeries[degree] = (Modulus - composedCoefficient) * inverseLinear mod Modulus
    powers[MaxN + degree] = inverseSeries[degree]
  for i in 0 ..< n: storeLe(output, 8 * i, inverseSeries[i])
  int64(bytes)
