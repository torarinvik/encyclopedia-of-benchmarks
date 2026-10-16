const
  MaxSignalLength = 64
  MaxInputLength = 2 + 2 * MaxSignalLength
  MaxOutputBytes = MaxSignalLength * 8
  MaxFixedSample = 128'i64
  SampleScale = 16.0

proc writeF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc convolve_1d*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "convolve_1d".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let rawSignalCount = input[0]
  let rawKernelCount = input[1]
  if rawSignalCount < 0 or rawSignalCount > int64(MaxSignalLength) or
      rawKernelCount < 0 or rawKernelCount > int64(MaxSignalLength): return -1
  let signalCount = int(rawSignalCount)
  let kernelCount = int(rawKernelCount)
  if int(length) != 2 + signalCount + kernelCount: return -1
  for index in 0 ..< signalCount + kernelCount:
    let value = input[index + 2]
    if value < -MaxFixedSample or value > MaxFixedSample: return -1

  let outputBytes = signalCount * 8
  if outputCapacity < csize_t(outputBytes) or (outputBytes > 0 and output == nil): return -2
  let center = kernelCount div 2
  for i in 0 ..< signalCount:
    var accumulated = 0.0
    for j in 0 ..< kernelCount:
      let signalIndex = i + j - center
      if signalIndex >= 0 and signalIndex < signalCount:
        let kernelValue = float64(input[2 + signalCount + j]) / SampleScale
        let signalValue = float64(input[2 + signalIndex]) / SampleScale
        accumulated += kernelValue * signalValue
    writeF64Le(output, i * 8, accumulated)
  int64(outputBytes)
