import std/math

const
  MinSide = 3
  MaxSide = 16
  MaxParseableInputLength = 258
  MaxOutputElements = 512
  MaxOutputBytes = 4096
  KernelX: array[9, int] = [-1, 0, 1, -2, 0, 2, -1, 0, 1]
  KernelY: array[9, int] = [1, 2, 1, 0, 0, 0, -1, -2, -1]

proc writeF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc sobelFilter*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "sobel_filter".} =
  if input == nil or inputLength < 2 or inputLength > MaxParseableInputLength.csize_t: return -1
  if input[0] < MinSide.int64 or input[0] > MaxSide.int64: return -1
  let side = int(input[0])
  let pixelCount = side * side
  if inputLength != csize_t(pixelCount + 1): return -1

  var image: array[MaxSide * MaxSide, int]
  for index in 0 ..< pixelCount:
    if input[index + 1] < 0 or input[index + 1] > 255: return -1
    image[index] = int(input[index + 1])

  var gradientX, gradientY: array[MaxSide * MaxSide, int]
  var maxX = 0
  var maxY = 0
  for y in 0 ..< side:
    for x in 0 ..< side:
      var gx = 0
      var gy = 0
      for ky in 0 ..< 3:
        let sampleY = max(0, min(side - 1, y + ky - 1))
        for kx in 0 ..< 3:
          let sampleX = max(0, min(side - 1, x + kx - 1))
          let pixel = image[sampleY * side + sampleX]
          let kernelIndex = ky * 3 + kx
          gx += pixel * KernelX[kernelIndex]
          gy += pixel * KernelY[kernelIndex]
      gx = abs(gx)
      gy = abs(gy)
      let index = y * side + x
      gradientX[index] = gx
      gradientY[index] = gy
      maxX = max(maxX, gx)
      maxY = max(maxY, gy)
  if maxX == 0 or maxY == 0: return -1

  var scaledX, scaledY, magnitude, theta: array[MaxSide * MaxSide, float64]
  var maxMagnitude = 0.0
  for index in 0 ..< pixelCount:
    scaledX[index] = (float64(gradientX[index]) * 255.0) / float64(maxX)
    scaledY[index] = (float64(gradientY[index]) * 255.0) / float64(maxY)
    magnitude[index] = sqrt((scaledX[index] * scaledX[index]) + (scaledY[index] * scaledY[index]))
    maxMagnitude = max(maxMagnitude, magnitude[index])
  if maxMagnitude == 0.0: return -1
  for index in 0 ..< pixelCount:
    let normalized = (magnitude[index] * 255.0) / maxMagnitude
    magnitude[index] = float64(uint8(normalized))
    theta[index] = arctan2(scaledY[index], scaledX[index])

  let outputElements = 2 * pixelCount
  let outputBytes = outputElements * 8
  if outputElements > MaxOutputElements or outputBytes > MaxOutputBytes: return -1
  if output == nil or capacity < csize_t(outputBytes): return -2
  for index in 0 ..< pixelCount:
    writeF64Le(output, index * 8, magnitude[index])
    writeF64Le(output, (pixelCount + index) * 8, theta[index])
  int64(outputElements)
