proc putF64Le(output: ptr UncheckedArray[uint8], value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc volume_conversions*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "volume_conversions".} =
  if input.isNil or length != 3: return -1
  let value = input[0]
  let fromUnit = input[1]
  let toUnit = input[2]
  if value < 0 or value > 1000 or fromUnit < 0 or fromUnit > 2 or toUnit < 0 or toUnit > 2 or fromUnit == toUnit:
    return -1
  if capacity < 8 or output.isNil: return -2
  let fromFactor = if fromUnit == 1: 0.001 else: 1.0
  let toFactor = if toUnit == 1: 0.001 else: 1.0
  let converted = (float64(value) * fromFactor) / toFactor
  putF64Le(output, converted)
  8
