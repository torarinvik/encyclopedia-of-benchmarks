const MaxSide = 16
const MaxKernelSide = 7

proc storeI64Le(output: ptr UncheckedArray[byte], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for index in 0 ..< 8:
    output[offset + index] = byte((bits shr (index * 8)) and 255)

proc imageConvolution(values: ptr UncheckedArray[int64], length: csize_t,
                      output: ptr UncheckedArray[byte], outputCapacity: csize_t): int64 {.cdecl, exportc: "image_convolution".} =
  if values == nil or length < 3 or length > 308: return -1
  let sideValue = values[0]
  let kernelSideValue = values[1]
  if sideValue < 1 or sideValue > MaxSide or kernelSideValue < 1 or
     kernelSideValue > MaxKernelSide or kernelSideValue mod 2 == 0: return -1
  let side = int(sideValue)
  let kernelSide = int(kernelSideValue)
  let pixelCount = side * side
  let kernelCount = kernelSide * kernelSide
  if int(length) != 2 + pixelCount + kernelCount: return -1
  for index in 0 ..< pixelCount:
    if values[2 + index] < 0 or values[2 + index] > 255: return -1
  for index in 0 ..< kernelCount:
    let weight = values[2 + pixelCount + index]
    if weight < -16 or weight > 16: return -1
  let outputBytes = pixelCount * 8
  if output == nil or int(outputCapacity) < outputBytes: return -2

  let radius = kernelSide div 2
  for row in 0 ..< side:
    for column in 0 ..< side:
      var total = 0'i64
      for kernelRow in 0 ..< kernelSide:
        let sourceRow = max(0, min(side - 1, row + kernelRow - radius))
        for kernelColumn in 0 ..< kernelSide:
          let sourceColumn = max(0, min(side - 1, column + kernelColumn - radius))
          let pixel = values[2 + sourceRow * side + sourceColumn]
          let weight = values[2 + pixelCount + kernelRow * kernelSide + kernelColumn]
          total += pixel * weight
      storeI64Le(output, (row * side + column) * 8, total)
  int64(outputBytes)
