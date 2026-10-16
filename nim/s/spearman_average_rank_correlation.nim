import std/math

const InvalidResult = -1.0e300

proc averageRank(values: ptr UncheckedArray[int64], offset, count, index: int): float64 =
  let sample = values[offset + index]
  var less = 0
  var equal = 0
  for j in 0 ..< count:
    if values[offset + j] < sample: inc less
    if values[offset + j] == sample: inc equal
  float64(less) + (float64(equal) + 1.0) / 2.0

proc spearman_average_rank_correlation*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "spearman_average_rank_correlation".} =
  if values == nil or length < 5 or length > csize_t(257): return InvalidResult
  let count = values[0]
  if count < 2 or count > 128 or length != csize_t(1 + 2 * count): return InvalidResult
  let n = int(count)
  for i in 0 ..< 2 * n:
    if values[1 + i] < -1_000_000 or values[1 + i] > 1_000_000: return InvalidResult
  let meanRank = (float64(n) + 1.0) / 2.0
  var covariance = 0.0
  var varianceX = 0.0
  var varianceY = 0.0
  for i in 0 ..< n:
    let dx = averageRank(values, 1, n, i) - meanRank
    let dy = averageRank(values, 1 + n, n, i) - meanRank
    covariance += dx * dy
    varianceX += dx * dx
    varianceY += dy * dy
  if varianceX == 0.0 or varianceY == 0.0: return InvalidResult
  return covariance / sqrt(varianceX * varianceY)
