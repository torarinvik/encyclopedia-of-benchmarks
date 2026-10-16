import std/math

const MaxSide = 32
const MaxPixels = MaxSide * MaxSide

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc bilateral_filter*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "bilateral_filter".} =
  if values == nil or length < 5 or length > csize_t(5 + MaxPixels): return -1
  let heightValue = values[0]
  let widthValue = values[1]
  let kernelValue = values[2]
  let spatialQ = values[3]
  let intensityQ = values[4]
  if heightValue < 1 or heightValue > MaxSide or widthValue < 1 or widthValue > MaxSide or
      kernelValue notin [1'i64, 3'i64, 5'i64, 7'i64] or spatialQ < 1 or spatialQ > 1_000_000 or
      intensityQ < 1 or intensityQ > 1_000_000: return -1
  let height = int(heightValue)
  let width = int(widthValue)
  let pixels = height * width
  if int(length) != 5 + pixels: return -1
  for index in 0 ..< pixels:
    if values[5 + index] < 0 or values[5 + index] > 1_000_000: return -1
  let required = pixels * 8
  if output == nil or outputCapacity < csize_t(required): return -2

  let kernelSize = int(kernelValue)
  let radius = kernelSize div 2
  let spatialVariance = float64(spatialQ) / 1_000_000.0
  let intensityVariance = float64(intensityQ) / 1_000_000.0
  var filtered: array[MaxPixels, int64]
  if height >= kernelSize and width >= kernelSize:
    for row in radius ..< height - radius:
      for column in radius ..< width - radius:
        let center = float64(values[5 + row * width + column]) / 1_000_000.0
        var weightedSum = 0.0
        var weightSum = 0.0
        for dy in -radius .. radius:
          for dx in -radius .. radius:
            let sample = float64(values[5 + (row + dy) * width + column + dx]) / 1_000_000.0
            let spatialDistanceSquared = float64(dx * dx + dy * dy)
            let difference = sample - center
            var weight = exp(-spatialDistanceSquared / (2.0 * spatialVariance))
            weight *= exp(-(difference * difference) / (2.0 * intensityVariance))
            weightedSum += sample * weight
            weightSum += weight
        filtered[row * width + column] = int64(weightedSum / weightSum * 1_000_000.0 + 0.5)
  for index in 0 ..< pixels: writeI64Le(output, index * 8, filtered[index])
  int64(required)
