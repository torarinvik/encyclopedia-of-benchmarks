const InvalidResult = -1.0e300

proc roundBinary64ToHundredth(value: float64): float64 =
  if value == 0.0: return 0.0
  let bits = cast[uint64](value)
  let fraction = bits and ((1'u64 shl 52) - 1)
  let exponentBits = int((bits shr 52) and 0x7ff'u64)
  let significand = (1'u64 shl 52) or fraction
  let binaryExponent = exponentBits - 1023 - 52
  let shift = -binaryExponent
  let scaledSignificand = significand * 100
  let denominator = 1'u64 shl shift
  var hundredths = scaledSignificand shr shift
  let remainder = scaledSignificand and (denominator - 1)
  let halfway = denominator shr 1
  if remainder > halfway or (remainder == halfway and (hundredths and 1) != 0):
    inc hundredths
  float64(hundredths) / 100.0

proc mass_to_moles*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "mass_to_moles".} =
  if input.isNil or length != 2: return InvalidResult
  let mass = input[0]
  let molarMass = input[1]
  if mass < 0 or mass > 1000 or molarMass < 1 or molarMass > 1000: return InvalidResult
  roundBinary64ToHundredth(float64(mass) / float64(molarMass))
