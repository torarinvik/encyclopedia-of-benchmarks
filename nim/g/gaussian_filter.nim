proc gaussian_filter_weight(kernelSize, distance: int64): int64 =
  if kernelSize == 3:
    if distance == 0: return 159154943091895'i64
    if distance == 1: return 96532352630054'i64
    return 58549831524319'i64
  if distance == 0: return 198943678864869'i64
  if distance == 1: return 91083053297916'i64
  if distance == 2: return 41700860491808'i64
  if distance == 4: return 8740975213082'i64
  if distance == 5: return 4001910066968'i64
  return 384051647741'i64

proc gaussian_filter*(v: ptr UncheckedArray[int64], n: csize_t,
                      outp: ptr UncheckedArray[uint8], cap: csize_t): int64 {.cdecl, exportc: "gaussian_filter".} =
  if v == nil or n < 3: return -1
  let height = v[0]
  let width = v[1]
  let kernelSize = v[2]
  if height < 3 or height > 12 or width < 3 or width > 12: return -1
  if kernelSize != 3 and kernelSize != 5: return -1
  if height < kernelSize or width < kernelSize: return -1
  if n != csize_t(3 + height * width): return -1
  for index in 3 ..< int(n):
    if v[index] < 0 or v[index] > 255: return -1

  let outputHeight = int(height - kernelSize + 1)
  let outputWidth = int(width - kernelSize + 1)
  let outputCount = outputHeight * outputWidth
  if cap < csize_t(outputCount) or outp == nil: return -2
  let center = kernelSize div 2
  for row in 0 ..< outputHeight:
    for column in 0 ..< outputWidth:
      var total = 0'i64
      for kernelRow in 0 ..< int(kernelSize):
        let dy = int64(kernelRow) - center
        for kernelColumn in 0 ..< int(kernelSize):
          let dx = int64(kernelColumn) - center
          let pixelIndex = 3 + (row + kernelRow) * int(width) + column + kernelColumn
          total += v[pixelIndex].int64 * gaussian_filter_weight(kernelSize, dx * dx + dy * dy)
      outp[row * outputWidth + column] = uint8(total div 1_000_000_000_000_000'i64)
  int64(outputCount)
