import math

const CoordinateLimit = 64'i64
const MaxPixels = 258

proc fractionPart(value: float64): float64 = value - floor(value)
proc reverseFractionPart(value: float64): float64 = 1.0 - fractionPart(value)

proc addPixel(pixelX: var array[MaxPixels, int64], pixelY: var array[MaxPixels, int64],
              intensities: var array[MaxPixels, float64], count: var int,
              x, y: int64, intensity: float64, steep: bool) =
  let outputX = if steep: y else: x
  let outputY = if steep: x else: y
  pixelX[count] = outputX
  pixelY[count] = outputY
  intensities[count] = min(1.0, max(0.0, intensity))
  inc count

proc addEndpoint(pixelX: var array[MaxPixels, int64], pixelY: var array[MaxPixels, int64],
                 intensities: var array[MaxPixels, float64], count: var int,
                 xPixel, yPixel: int64, yEnd, xGap: float64, steep: bool) =
  let fractionalY = fractionPart(yEnd)
  let complement = reverseFractionPart(yEnd)
  addPixel(pixelX, pixelY, intensities, count, xPixel, yPixel,
           complement * xGap, steep)
  addPixel(pixelX, pixelY, intensities, count, xPixel, yPixel + 1,
           fractionalY * xGap, steep)

proc writeI32(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xFF'u32)

proc writeF64(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xFF'u64)

proc wus_line*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "wus_line".} =
  if values == nil or length != 4: return -1
  for index in 0 ..< 4:
    if values[index] < -CoordinateLimit or values[index] > CoordinateLimit: return -1

  var x0 = values[0]
  var y0 = values[1]
  var x1 = values[2]
  var y1 = values[3]
  let steep = abs(y1 - y0) > abs(x1 - x0)
  if steep:
    swap(x0, y0)
    swap(x1, y1)
  if x0 > x1:
    swap(x0, x1)
    swap(y0, y1)

  let deltaX = float64(x1) - float64(x0)
  let deltaY = float64(y1) - float64(y0)
  let gradient = if deltaX == 0.0: 1.0 else: deltaY / deltaX
  let firstXEnd = floor(float64(x0) + 0.5)
  let firstYEnd = float64(y0) + gradient * (firstXEnd - float64(x0))
  let firstXPixel = int64(firstXEnd)
  let firstYPixel = int64(floor(firstYEnd))
  let firstGap = reverseFractionPart(float64(x0) + 0.5)
  let secondXEnd = floor(float64(x1) + 0.5)
  let secondYEnd = float64(y1) + gradient * (secondXEnd - float64(x1))
  let secondXPixel = int64(secondXEnd)
  let secondYPixel = int64(floor(secondYEnd))
  let secondGap = fractionPart(float64(x1) + 0.5)

  var pixelX: array[MaxPixels, int64]
  var pixelY: array[MaxPixels, int64]
  var intensities: array[MaxPixels, float64]
  var pixelCount = 0
  addEndpoint(pixelX, pixelY, intensities, pixelCount,
              firstXPixel, firstYPixel, firstYEnd, firstGap, steep)
  addEndpoint(pixelX, pixelY, intensities, pixelCount,
              secondXPixel, secondYPixel, secondYEnd, secondGap, steep)

  var intersectionY = firstYEnd + gradient
  var x = firstXPixel + 1
  while x < secondXPixel:
    let yFloor = int64(floor(intersectionY))
    let fractional = fractionPart(intersectionY)
    let complement = reverseFractionPart(intersectionY)
    addPixel(pixelX, pixelY, intensities, pixelCount, x, yFloor, complement, steep)
    addPixel(pixelX, pixelY, intensities, pixelCount, x, yFloor + 1, fractional, steep)
    intersectionY += gradient
    inc x

  let required = pixelCount * 16
  if output == nil or outputCapacity < csize_t(required): return -2
  for index in 0 ..< pixelCount:
    let offset = index * 16
    writeI32(output, offset, pixelX[index])
    writeI32(output, offset + 4, pixelY[index])
    writeF64(output, offset + 8, intensities[index])
  int64(required)
