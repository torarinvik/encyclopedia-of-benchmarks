const InvalidResult = -1.0e300

proc parseScientificFour(value: float64): float64 =
  if value == 0.0: return 0.0
  var normalized = value
  var decimalExponent = 0
  while normalized >= 10.0:
    normalized /= 10.0
    inc decimalExponent
  while normalized < 1.0:
    normalized *= 10.0
    dec decimalExponent
  let bits = cast[uint64](value)
  let fraction = bits and ((1'u64 shl 52) - 1)
  let exponentBits = int((bits shr 52) and 0x7ff'u64)
  let significand = (1'u64 shl 52) or fraction
  let binaryExponent = exponentBits - 1023 - 52
  let decimalShift = decimalExponent - 4
  var denominator = 1'u64
  for _ in 0 ..< decimalShift: denominator *= 5
  let binaryShift = binaryExponent - decimalShift
  var numerator = significand
  if binaryShift >= 0: numerator = numerator shl binaryShift
  else: denominator = denominator shl (-binaryShift)
  var rounded = numerator div denominator
  let remainder = numerator mod denominator
  if remainder * 2 > denominator or (remainder * 2 == denominator and (rounded and 1) != 0):
    inc rounded
  var decimalScale = 1.0
  for _ in 0 ..< decimalShift: decimalScale *= 10.0
  float64(rounded) * decimalScale

proc moles_to_molecules*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "moles_to_molecules".} =
  if input.isNil or length != 1: return InvalidResult
  let molesMicro = input[0]
  if molesMicro < 0 or molesMicro > 2_000_000: return InvalidResult
  let moles = float64(molesMicro) / 1_000_000.0
  parseScientificFour(moles * 6.022e23)
