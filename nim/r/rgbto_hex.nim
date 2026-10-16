const RgbChannelCount = 3
const RgbHexOutputLength = 7

proc hexDigit(value: int64): uint8 =
  if value < 10: uint8(48 + value) else: uint8(87 + value)

proc rgbto_hex*(input: ptr UncheckedArray[int64], length: csize_t,
                output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "rgbto_hex".} =
  if length != RgbChannelCount or input.isNil: return -1
  for i in 0 ..< RgbChannelCount:
    if input[i] < 0 or input[i] > 255: return -1
  if capacity < RgbHexOutputLength or output.isNil: return -2
  output[0] = uint8(ord('#'))
  for i in 0 ..< RgbChannelCount:
    output[1 + 2 * i] = hexDigit(input[i] div 16)
    output[2 + 2 * i] = hexDigit(input[i] mod 16)
  RgbHexOutputLength.int64
