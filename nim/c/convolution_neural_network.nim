import std/math

const MaxImageSide = 8
const MaxKernelSide = 4
const MaxFilters = 3
const MaxHidden = 8
const MaxOutputs = 4
const MaxEntryMicro = 1_000_000'i64

proc sigmoid(value: float64): float64 = 1.0 / (1.0 + exp(-value))

proc roundThree(value: float64): float64 =
  let scaled = value * 1000.0
  let lower = floor(scaled)
  var integer = int64(lower)
  let fraction = scaled - lower
  if fraction > 0.5 or (fraction == 0.5 and integer mod 2 != 0): inc integer
  float64(integer) / 1000.0

proc writeF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc convolution_neural_network*(values: ptr UncheckedArray[int64], length: csize_t,
                                 output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "convolution_neural_network".} =
  if values.isNil or length < 7 or length > 2048: return -1
  let imageSideValue = values[0]
  let kernelSideValue = values[1]
  let strideValue = values[2]
  let filtersValue = values[3]
  let poolValue = values[4]
  let hiddenValue = values[5]
  let outputsValue = values[6]
  if imageSideValue < 2 or imageSideValue > MaxImageSide or kernelSideValue < 1 or kernelSideValue > MaxKernelSide or
     strideValue < 1 or strideValue > 4 or filtersValue < 1 or filtersValue > MaxFilters or
     poolValue < 1 or poolValue > 2 or hiddenValue < 1 or hiddenValue > MaxHidden or
     outputsValue < 1 or outputsValue > MaxOutputs or kernelSideValue > imageSideValue: return -1
  let imageSide = int(imageSideValue)
  let kernelSide = int(kernelSideValue)
  let stride = int(strideValue)
  let filters = int(filtersValue)
  let poolSide = int(poolValue)
  let hidden = int(hiddenValue)
  let outputs = int(outputsValue)
  let convSide = (imageSide - kernelSide) div stride + 1
  if convSide < poolSide or convSide mod poolSide != 0: return -1
  let pooledSide = convSide div poolSide
  let featureCount = filters * pooledSide * pooledSide
  let imageCount = imageSide * imageSide
  let kernelCount = filters * kernelSide * kernelSide
  let hiddenWeightCount = hidden * featureCount
  let outputWeightCount = outputs * hidden
  let expectedLength = 7 + imageCount + kernelCount + filters + hiddenWeightCount + outputWeightCount + hidden + outputs
  if int(length) != expectedLength or featureCount > 192: return -1

  var image: array[64, float64]
  var kernels: array[48, float64]
  var convBias: array[3, float64]
  var hiddenWeights: array[1536, float64]
  var outputWeights: array[32, float64]
  var hiddenBias: array[8, float64]
  var outputBias: array[4, float64]
  var featureMaps: array[192, float64]
  var flattened: array[192, float64]
  var hiddenOutput: array[8, float64]
  var position = 7
  for index in 0 ..< imageCount:
    let raw = values[position]
    inc position
    if raw < 0 or raw > MaxEntryMicro: return -1
    image[index] = float64(raw) / 1_000_000.0
  for index in 0 ..< kernelCount:
    let raw = values[position]
    inc position
    if raw < -500_000 or raw > 500_000: return -1
    kernels[index] = float64(raw) / 1_000_000.0
  for index in 0 ..< filters:
    let raw = values[position]
    inc position
    if raw < -MaxEntryMicro or raw > MaxEntryMicro: return -1
    convBias[index] = float64(raw) / 1_000_000.0
  for index in 0 ..< hiddenWeightCount:
    let raw = values[position]
    inc position
    if raw < -500_000 or raw > 500_000: return -1
    hiddenWeights[index] = float64(raw) / 1_000_000.0
  for index in 0 ..< outputWeightCount:
    let raw = values[position]
    inc position
    if raw < -500_000 or raw > 500_000: return -1
    outputWeights[index] = float64(raw) / 1_000_000.0
  for index in 0 ..< hidden:
    let raw = values[position]
    inc position
    if raw < -MaxEntryMicro or raw > MaxEntryMicro: return -1
    hiddenBias[index] = float64(raw) / 1_000_000.0
  for index in 0 ..< outputs:
    let raw = values[position]
    inc position
    if raw < -MaxEntryMicro or raw > MaxEntryMicro: return -1
    outputBias[index] = float64(raw) / 1_000_000.0
  let outputBytes = outputs * 8
  if output.isNil or outputCapacity < csize_t(outputBytes): return -2

  for filter in 0 ..< filters:
    for top in 0 ..< convSide:
      for left in 0 ..< convSide:
        var total = 0.0
        for row in 0 ..< kernelSide:
          for column in 0 ..< kernelSide:
            total += image[(top * stride + row) * imageSide + left * stride + column] *
                     kernels[filter * kernelSide * kernelSide + row * kernelSide + column]
        featureMaps[(filter * convSide + top) * convSide + left] = sigmoid(total - convBias[filter])
  var featureIndex = 0
  let poolArea = poolSide * poolSide
  for filter in 0 ..< filters:
    for top in countup(0, convSide - 1, poolSide):
      for left in countup(0, convSide - 1, poolSide):
        var total = 0.0
        for row in 0 ..< poolSide:
          for column in 0 ..< poolSide:
            total += featureMaps[(filter * convSide + top + row) * convSide + left + column]
        flattened[featureIndex] = total / float64(poolArea)
        inc featureIndex
  for unit in 0 ..< hidden:
    var total = 0.0
    for index in 0 ..< featureCount: total += flattened[index] * hiddenWeights[unit * featureCount + index]
    hiddenOutput[unit] = sigmoid(total - hiddenBias[unit])
  for unit in 0 ..< outputs:
    var total = 0.0
    for index in 0 ..< hidden: total += hiddenOutput[index] * outputWeights[unit * hidden + index]
    writeF64Le(output, unit * 8, roundThree(sigmoid(total - outputBias[unit])))
  int64(outputBytes)
