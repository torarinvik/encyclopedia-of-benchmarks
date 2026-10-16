const MaxSideLength = 32
const MaxParseableInputLength = 1026

proc mean_threshold*(input: ptr UncheckedArray[int64], length: csize_t,
                     output: ptr UncheckedArray[uint8],
                     outputCapacity: csize_t): int64
    {.cdecl, exportc: "mean_threshold".} =
  if input.isNil or length < 1 or length > MaxParseableInputLength: return -1
  if input[0] < 1 or input[0] > MaxSideLength: return -1

  let side = int(input[0])
  let pixelCount = side * side
  if int(length) != pixelCount + 1: return -1

  var sum = 0'i64
  for index in 0 ..< pixelCount:
    let pixel = input[1 + index]
    if pixel < 0 or pixel > 255: return -1
    sum += pixel

  let mean = sum div int64(pixelCount)
  if outputCapacity < csize_t(pixelCount) or output.isNil: return -2
  for index in 0 ..< pixelCount:
    output[index] = if input[1 + index] > mean: 255'u8 else: 0'u8
  int64(pixelCount)

