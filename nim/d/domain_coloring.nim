const MaxOutputBytes = 768

proc phaseHue(realPart, imaginaryPart: int64): int64 =
  if realPart == 0 and imaginaryPart == 0: return 0
  let absReal = abs(realPart)
  let absImaginary = abs(imaginaryPart)
  let high = max(absReal, absImaginary)
  let low = min(absReal, absImaginary)
  let step = 192'i64 * low div high
  var hue: int64
  if imaginaryPart >= 0:
    if realPart >= 0:
      hue = if absReal >= absImaginary: step else: 384 - step
    else:
      hue = if absReal < absImaginary: 384 + step else: 768 - step
  elif realPart < 0:
    hue = if absReal >= absImaginary: 768 + step else: 1152 - step
  else:
    hue = if absReal < absImaginary: 1152 + step else: 1536 - step
  if hue == 1536: 0 else: hue

proc storePixel(pixels: var array[MaxOutputBytes, uint8], offset: int,
    hue, magnitude16: int64) =
  let value = 128'i64 + 8 * (magnitude16 mod 16)
  let sector = hue div 256
  let fraction = hue mod 256
  let rising = uint8(value * fraction div 255)
  let falling = uint8(value * (255 - fraction) div 255)
  let bright = uint8(value)
  var red, green, blue: uint8
  case sector
  of 0: red = bright; green = rising
  of 1: red = falling; green = bright
  of 2: green = bright; blue = rising
  of 3: green = falling; blue = bright
  of 4: red = rising; blue = bright
  else: red = bright; blue = falling
  pixels[offset] = red
  pixels[offset + 1] = green
  pixels[offset + 2] = blue

proc domain_coloring*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "domain_coloring".} =
  if input == nil or length != csize_t(6): return -1
  let widthValue = input[0]
  let heightValue = input[1]
  let xStart = input[2]
  let yStart = input[3]
  let xStep = input[4]
  let yStep = input[5]
  if widthValue < 1 or widthValue > 16 or heightValue < 1 or heightValue > 16 or
      xStart < -32 or xStart > 32 or yStart < -32 or yStart > 32 or
      xStep < -8 or xStep > 8 or yStep < -8 or yStep > 8: return -1
  let xEnd = xStart + (widthValue - 1) * xStep
  let yEnd = yStart + (heightValue - 1) * yStep
  if xEnd < -32 or xEnd > 32 or yEnd < -32 or yEnd > 32: return -1

  let width = int(widthValue)
  let height = int(heightValue)
  let byteCount = 3 * width * height
  var rendered: array[MaxOutputBytes, uint8]
  var offset = 0
  for row in 0 ..< height:
    let yQ = yStart + int64(row) * yStep
    for column in 0 ..< width:
      let xQ = xStart + int64(column) * xStep
      let xSquared = xQ * xQ
      let ySquared = yQ * yQ
      storePixel(rendered, offset, phaseHue(xSquared - ySquared, 2 * xQ * yQ),
                 xSquared + ySquared)
      offset += 3

  if output == nil or outputCapacity < csize_t(byteCount): return -2
  for index in 0 ..< byteCount: output[index] = rendered[index]
  int64(byteCount)
