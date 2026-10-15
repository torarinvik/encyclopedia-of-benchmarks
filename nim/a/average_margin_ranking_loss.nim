const MaxLength = 256
const InvalidResult = -1.0e300

proc average_margin_ranking_loss*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "average_margin_ranking_loss".} =
  if values == nil or length < 5 or length > csize_t(2 * MaxLength + 3): return InvalidResult
  let countValue = values[0]
  let marginValue = values[1]
  let labelValue = values[2]
  if countValue < 1 or countValue > MaxLength or length != csize_t(2 * countValue + 3) or
      marginValue < 0 or marginValue > 1000 or (labelValue != 1 and labelValue != -1): return InvalidResult
  let count = int(countValue)
  var total = 0.0
  for index in 0 ..< count:
    let first = values[index + 3]
    let second = values[index + 3 + count]
    if first < -1_000 or first > 1_000 or second < -1_000 or second > 1_000: return InvalidResult
    let loss = float64(marginValue) - float64(labelValue) * (float64(first) - float64(second))
    if loss > 0.0: total += loss
  return total / float64(count)
