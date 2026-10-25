const MaxBins = 256
const MaxSamples = 1024

proc parboil_histo(input: ptr UncheckedArray[int64], inputLength: int,
                   output: ptr UncheckedArray[uint8], outputCapacity: int): int64 {.exportc.} =
  if input.isNil or inputLength < 3 or inputLength > 3 + MaxSamples: return -1
  let iterations = input[0]
  let bins = input[1]
  let samples = input[2]
  if iterations < 0 or iterations > 8 or bins < 1 or bins > int64(MaxBins) or
     samples < 0 or samples > int64(MaxSamples) or inputLength != 3 + int(samples): return -1
  for i in 0 ..< int(samples):
    if input[3+i] < 0 or input[3+i] >= bins: return -1
  if output.isNil or outputCapacity < int(bins): return -2
  var histogram: array[MaxBins, uint8]
  for _ in 0 ..< int(iterations):
    for i in 0 ..< int(bins): histogram[i] = 0
    for i in 0 ..< int(samples):
      let bin = int(input[3+i])
      if histogram[bin] < 255'u8: inc histogram[bin]
  for i in 0 ..< int(bins): output[i] = histogram[i]
  int64(bins)
