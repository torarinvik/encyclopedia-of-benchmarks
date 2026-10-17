proc roundedAdd(left, right: float64): float64 {.noinline.} = left + right
proc roundedSubtract(left, right: float64): float64 {.noinline.} = left - right
proc roundedMultiply(left, right: float64): float64 {.noinline.} = left * right
proc roundedDivide(left, right: float64): float64 {.noinline.} = left / right

proc mandelbrot*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "mandelbrot".} =
  if input == nil or length != 6: return -1
  let widthValue = input[0]
  let heightValue = input[1]
  let centerXq = input[2]
  let centerYq = input[3]
  let figureWidthQ = input[4]
  let maxStepValue = input[5]
  if widthValue < 1 or widthValue > 16 or heightValue < 1 or heightValue > 16 or
      centerXq < -64 or centerXq > 64 or centerYq < -64 or centerYq > 64 or
      figureWidthQ < 1 or figureWidthQ > 64 or maxStepValue < 2 or maxStepValue > 64:
    return -1
  let width = int(widthValue)
  let height = int(heightValue)
  let maxStep = int(maxStepValue)
  let pixelCount = width * height
  if output == nil or capacity < csize_t(pixelCount): return -2

  let centerX = float64(centerXq) / 16.0
  let centerY = float64(centerYq) / 16.0
  let figureWidth = float64(figureWidthQ) / 16.0
  let figureHeight = roundedMultiply(roundedDivide(figureWidth, float64(width)), float64(height))
  var offset = 0
  for imageX in 0 ..< width:
    let xPosition = roundedSubtract(roundedDivide(float64(imageX), float64(width)), 0.5)
    let figureX = roundedAdd(centerX, roundedMultiply(xPosition, figureWidth))
    for imageY in 0 ..< height:
      let yPosition = roundedSubtract(roundedDivide(float64(imageY), float64(height)), 0.5)
      let figureY = roundedAdd(centerY, roundedMultiply(yPosition, figureHeight))
      var a = figureX
      var b = figureY
      var currentStep = 0
      for step in 0 ..< maxStep:
        currentStep = step
        let aNew = roundedAdd(roundedSubtract(roundedMultiply(a, a), roundedMultiply(b, b)), figureX)
        b = roundedAdd(roundedMultiply(roundedMultiply(2.0, a), b), figureY)
        a = aNew
        if roundedAdd(roundedMultiply(a, a), roundedMultiply(b, b)) > 4.0: break
      let normalizedDistance = roundedDivide(float64(currentStep), float64(maxStep - 1))
      output[offset] = if normalizedDistance >= 1.0: 0'u8 else: 255'u8
      inc offset
  int64(pixelCount)
