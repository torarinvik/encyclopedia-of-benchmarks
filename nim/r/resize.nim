const MaxInputLength = 3077
const MaxOutputBytes = 3072

proc resize*(input: ptr UncheckedArray[int64], length: csize_t,
             output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "resize".} =
  if input == nil or length < csize_t(4) or length > csize_t(MaxInputLength): return -1
  let srcWidth64 = input[0]
  let srcHeight64 = input[1]
  let dstWidth64 = input[2]
  let dstHeight64 = input[3]
  if srcWidth64 < 1 or srcWidth64 > 32 or srcHeight64 < 1 or srcHeight64 > 32 or
      dstWidth64 < 1 or dstWidth64 > 32 or dstHeight64 < 1 or dstHeight64 > 32:
    return -1

  let srcWidth = int(srcWidth64)
  let srcHeight = int(srcHeight64)
  let dstWidth = int(dstWidth64)
  let dstHeight = int(dstHeight64)
  let expectedLength = 4 + 3 * srcWidth * srcHeight
  if length != csize_t(expectedLength): return -1
  for index in 4 ..< expectedLength:
    if input[index] < 0 or input[index] > 255: return -1

  let needed = 3 * dstWidth * dstHeight
  if needed > MaxOutputBytes: return -1
  if output == nil or capacity < csize_t(needed): return -2

  let ratioX = float64(srcWidth) / float64(dstWidth)
  let ratioY = float64(srcHeight) / float64(dstHeight)
  var outIndex = 0
  for y in 0 ..< dstHeight:
    let srcY = int(ratioY * float64(y))
    for x in 0 ..< dstWidth:
      let srcX = int(ratioX * float64(x))
      let srcIndex = 4 + 3 * (srcY * srcWidth + srcX)
      output[outIndex] = uint8(input[srcIndex])
      output[outIndex + 1] = uint8(input[srcIndex + 1])
      output[outIndex + 2] = uint8(input[srcIndex + 2])
      outIndex += 3
  int64(needed)
