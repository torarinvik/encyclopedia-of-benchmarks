import std/[math]

const
  Pi = 3.14159265358979323846264338327950288

proc putF32Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint32](float32(value))
  for byte in 0..<4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc gabor_filter*(values: ptr UncheckedArray[int64], length: csize_t,
                   output: ptr UncheckedArray[uint8], capacity: csize_t): int64
                   {.cdecl, exportc: "gabor_filter".} =
  if values == nil or length < 1 or length > 7: return -1
  if length != 6: return -1
  let requested = values[0]
  let sigma = values[1]
  let theta = values[2]
  let wavelength = values[3]
  let gamma = values[4]
  let phase = values[5]
  if requested < 1 or requested > 7 or sigma < 1 or sigma > 8: return -1
  if theta < 0 or theta > 359 or wavelength < 1 or wavelength > 8: return -1
  if gamma < 0 or gamma > 4 or phase < -6 or phase > 6: return -1

  var side = int(requested)
  if side mod 2 == 0: inc side
  let outputBytes = side * side * 4
  if output == nil or capacity < csize_t(outputBytes): return -2

  let angle = (float64(theta) / 180.0) * Pi
  let cosine = cos(angle)
  let sine = sin(angle)
  let center = side div 2
  var offset = 0
  for y in 0..<side:
    let py = float64(y - center)
    for x in 0..<side:
      let px = float64(x - center)
      let kernelX = cosine * px + sine * py
      let kernelY = -sine * px + cosine * py
      let exponent = -(kernelX * kernelX + float64(gamma * gamma) * kernelY * kernelY) /
                     (2.0 * float64(sigma) * float64(sigma))
      let phaseAngle = 2.0 * Pi * kernelX / float64(wavelength) + float64(phase)
      putF32Le(output, offset, exp(exponent) * cos(phaseAngle))
      offset += 4
  int64(outputBytes)
