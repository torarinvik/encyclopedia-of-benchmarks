const MaxLength = 62
const InvalidResult = -1'i64

proc type7Quantile(sorted: array[MaxLength, int64], count: int, probability: float64): float64 =
  let h = float64(count - 1) * probability + 1.0
  let order = int(h)
  let fraction = h - float64(order)
  let lower = order - 1
  if fraction == 0.0 or lower + 1 >= count: return float64(sorted[lower])
  (1.0 - fraction) * float64(sorted[lower]) + fraction * float64(sorted[lower + 1])

proc iqr_outlier_indices*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "iqr_outlier_indices".} =
  if values == nil or length == 0 or length > csize_t(MaxLength): return InvalidResult
  var sorted: array[MaxLength, int64]
  let n = int(length)
  for i in 0 ..< n:
    let value = values[i]
    if value < -1_000_000 or value > 1_000_000: return InvalidResult
    var position = i
    while position > 0 and sorted[position - 1] > value:
      sorted[position] = sorted[position - 1]
      dec position
    sorted[position] = value
  let q1 = type7Quantile(sorted, n, 0.25)
  let q3 = type7Quantile(sorted, n, 0.75)
  let iqr = q3 - q1
  let lowerBound = q1 - 1.5 * iqr
  let upperBound = q3 + 1.5 * iqr
  var mask = 0'i64
  for i in 0 ..< n:
    let value = float64(values[i])
    if value < lowerBound or value > upperBound: mask = mask or (1'i64 shl i)
  return mask
