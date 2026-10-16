import std/math

const InvalidResult = -1.0e300

proc component(channel: int64): float64 =
  let srgb = float64(channel) / 255.0
  if srgb <= 0.03928: return srgb / 12.92
  pow((srgb + 0.055) / 1.055, 2.4)

proc luminance(red, green, blue: int64): float64 =
  0.2126 * component(red) + 0.7152 * component(green) + 0.0722 * component(blue)

proc color_contrast_ratio*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "color_contrast_ratio".} =
  if values == nil or length != 6: return InvalidResult
  for i in 0 .. 5:
    if values[i] < 0 or values[i] > 255: return InvalidResult
  let first = luminance(values[0], values[1], values[2])
  let second = luminance(values[3], values[4], values[5])
  if first > second: return (first + 0.05) / (second + 0.05)
  (second + 0.05) / (first + 0.05)
