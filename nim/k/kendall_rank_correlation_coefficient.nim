import std/math

const InvalidResult = -1.0e300

proc kendall_rank_correlation_coefficient*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "kendall_rank_correlation_coefficient".} =
  if values == nil or length < 5 or length > csize_t(257): return InvalidResult
  let count = values[0]
  if count < 2 or count > 128 or length != csize_t(1 + 2 * count): return InvalidResult
  for i in 0 ..< 2 * int(count):
    if values[1 + i] < -1_000_000 or values[1 + i] > 1_000_000: return InvalidResult

  var concordant = 0'i64
  var discordant = 0'i64
  var tiesX = 0'i64
  var tiesY = 0'i64
  let n = int(count)
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      let x1 = values[1 + i]
      let x2 = values[1 + j]
      let y1 = values[1 + n + i]
      let y2 = values[1 + n + j]
      if x1 == x2: inc tiesX
      if y1 == y2: inc tiesY
      if (x1 < x2 and y1 < y2) or (x1 > x2 and y1 > y2): inc concordant
      elif (x1 < x2 and y1 > y2) or (x1 > x2 and y1 < y2): inc discordant
  let pairs = float64(n * (n - 1) div 2)
  let denominator = sqrt((pairs - float64(tiesX)) * (pairs - float64(tiesY)))
  if denominator == 0.0: return InvalidResult
  return float64(concordant - discordant) / denominator
