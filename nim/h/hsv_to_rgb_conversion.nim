proc sectionRemainderTwo(section: float64): float64 =
  if section < 2.0: return section
  if section < 4.0: return section - 2.0
  if section < 6.0: return section - 4.0
  section - 6.0

proc roundChannel(channel: float64): uint8 =
  uint8(int(255.0 * channel + 0.5))

proc hsv_to_rgb_conversion*(input: ptr UncheckedArray[int64], length: csize_t,
                            output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "hsv_to_rgb_conversion".} =
  if input.isNil or length != 3: return -1
  if input[0] < 0 or input[0] > 360_000 or input[1] < 0 or input[1] > 255_000_000 or
      input[2] < 0 or input[2] > 255_000_000: return -1
  if output.isNil or capacity < 3: return -2

  let hue = float64(input[0]) / 1000.0
  let saturation = float64(input[1]) / 255_000_000.0
  let value = float64(input[2]) / 255_000_000.0
  let chroma = value * saturation
  let hueSection = hue / 60.0
  let second = chroma * (1.0 - abs(sectionRemainderTwo(hueSection) - 1.0))
  let matched = value - chroma
  var red, green, blue: float64
  if hueSection >= 0.0 and hueSection <= 1.0:
    red = chroma + matched; green = second + matched; blue = matched
  elif hueSection > 1.0 and hueSection <= 2.0:
    red = second + matched; green = chroma + matched; blue = matched
  elif hueSection > 2.0 and hueSection <= 3.0:
    red = matched; green = chroma + matched; blue = second + matched
  elif hueSection > 3.0 and hueSection <= 4.0:
    red = matched; green = second + matched; blue = chroma + matched
  elif hueSection > 4.0 and hueSection <= 5.0:
    red = second + matched; green = matched; blue = chroma + matched
  else:
    red = chroma + matched; green = matched; blue = second + matched
  output[0] = roundChannel(red)
  output[1] = roundChannel(green)
  output[2] = roundChannel(blue)
  3'i64
