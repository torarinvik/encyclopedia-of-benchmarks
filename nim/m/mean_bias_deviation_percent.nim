const InvalidResult = -1.0e300

proc mean_bias_deviation_percent*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "mean_bias_deviation_percent".} =
  if input.isNil or length < 1 or length > 131: return InvalidResult
  if input[0] < 1 or input[0] > 64: return InvalidResult
  let count = int(input[0])
  if int(length) != 1 + 2 * count: return InvalidResult
  var differenceSum = 0'i64
  var actualSum = 0'i64
  for index in 0..<count:
    let prediction = input[1 + index]
    let actual = input[1 + count + index]
    if prediction < -1000 or prediction > 1000 or actual < -1000 or actual > 1000: return InvalidResult
    differenceSum += prediction - actual
    actualSum += actual
  if actualSum == 0: return InvalidResult
  let numerator = float64(differenceSum) / float64(count)
  let denominator = float64(actualSum) / float64(count)
  numerator / denominator * 100.0
