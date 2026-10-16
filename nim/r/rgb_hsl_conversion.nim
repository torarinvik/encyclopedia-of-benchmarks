const OutputCount = 4

proc rgb_hsl_conversion*(input: ptr UncheckedArray[int64], length: csize_t,
                         output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "rgb_hsl_conversion".} =
  if input.isNil or length != 3: return -1
  for i in 0 ..< 3:
    if input[i] < 0 or input[i] > 255: return -1
  if output.isNil or capacity < OutputCount: return -2

  let red = float64(input[0]) / 255.0
  let green = float64(input[1]) / 255.0
  let blue = float64(input[2]) / 255.0
  let minimum = min(red, min(green, blue))
  let maximum = max(red, max(green, blue))
  var channel = 0
  if maximum == green: channel = 1
  elif maximum == blue: channel = 2
  let luminance = (minimum + maximum) / 2.0
  var saturation = 0.0
  if minimum != maximum:
    if luminance <= 0.5: saturation = (maximum - minimum) / (maximum + minimum)
    else: saturation = (maximum - minimum) / (2.0 - maximum - minimum)
  var hue = 0.0
  if saturation != 0.0:
    case channel
    of 0: hue = (green - blue) / (maximum - minimum)
    of 1: hue = 2.0 + (blue - red) / (maximum - minimum)
    else: hue = 4.0 + (red - green) / (maximum - minimum)
  hue *= 60.0
  if hue < 0.0: hue += 360.0
  let h = int64(hue + 0.5)
  output[0] = uint8(h and 255)
  output[1] = uint8(h shr 8)
  output[2] = uint8(saturation * 100.0 + 0.5)
  output[3] = uint8(luminance * 100.0 + 0.5)
  OutputCount.int64
