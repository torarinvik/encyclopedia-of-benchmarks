import math

const OutputLength = 4

proc roundTiesToEven(value: float64): int64 =
  let lower = floor(value)
  let fraction = value - lower
  let base = int64(lower)
  if fraction < 0.5: return base
  if fraction > 0.5: return base + 1
  if base mod 2 == 0: return base
  base + 1

proc rgb_cmyk_conversion*(input: ptr UncheckedArray[int64], length: csize_t,
                          output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "rgb_cmyk_conversion".} =
  if input.isNil or length != 3: return -1
  for i in 0 ..< 3:
    if input[i] < 0 or input[i] > 255: return -1
  if output.isNil or capacity < OutputLength: return -2
  let red = float64(input[0]) / 255.0
  let green = float64(input[1]) / 255.0
  let blue = float64(input[2]) / 255.0
  let maximum = max(max(red, green), blue)
  let key = 1.0 - maximum
  if key == 1.0:
    output[0] = 0; output[1] = 0; output[2] = 0; output[3] = 100
    return OutputLength
  let denominator = 1.0 - key
  output[0] = uint8(roundTiesToEven(100.0 * (1.0 - red - key) / denominator))
  output[1] = uint8(roundTiesToEven(100.0 * (1.0 - green - key) / denominator))
  output[2] = uint8(roundTiesToEven(100.0 * (1.0 - blue - key) / denominator))
  output[3] = uint8(roundTiesToEven(100.0 * key))
  OutputLength
