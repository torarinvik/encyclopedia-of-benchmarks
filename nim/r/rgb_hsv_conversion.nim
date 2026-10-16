proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for i in 0 ..< 8: output[offset + i] = uint8((bits shr (8 * i)) and 0xFF'u64)

proc rgb_hsv_conversion*(input: ptr UncheckedArray[int64], length: csize_t,
                         output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "rgb_hsv_conversion".} =
  if input.isNil or length != 3: return -1
  for i in 0 ..< 3: if input[i] < 0 or input[i] > 255: return -1
  if output.isNil or capacity < 24: return -2
  let red = float64(input[0]) / 255.0
  let green = float64(input[1]) / 255.0
  let blue = float64(input[2]) / 255.0
  let value = max(max(red, green), blue)
  let chroma = value - min(min(red, green), blue)
  let saturation = if value == 0.0: 0.0 else: chroma / value
  var hue = 0.0
  if chroma != 0.0:
    if value == red: hue = 60.0 * (0.0 + (green - blue) / chroma)
    elif value == green: hue = 60.0 * (2.0 + (blue - red) / chroma)
    else: hue = 60.0 * (4.0 + (red - green) / chroma)
  hue += 360.0
  if hue >= 360.0: hue -= 360.0
  putF64Le(output, 0, hue)
  putF64Le(output, 8, saturation)
  putF64Le(output, 16, value)
  24'i64
