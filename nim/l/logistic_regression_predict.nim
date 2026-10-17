const MaxInputLength = 2051
proc logistic_regression_predict*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "logistic_regression_predict".} =
  if values == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let rows = values[0]; let features = values[1]
  if rows < 1 or rows > 63 or features < 1 or features > 32: return -1
  let rowsInt = int(rows); let featuresInt = int(features)
  if int(length) != 2 + rowsInt * featuresInt + featuresInt: return -1
  let thetaOffset = 2 + rowsInt * featuresInt
  for i in 0 ..< rowsInt * featuresInt + featuresInt:
    if values[2 + i] < -1000 or values[2 + i] > 1000: return -1
  var mask = 0'u64
  for row in 0 ..< rowsInt:
    var score = 0'i64
    for feature in 0 ..< featuresInt:
      score += values[2 + row * featuresInt + feature] * values[thetaOffset + feature]
    if score >= 0: mask = mask or (1'u64 shl row)
  int64(mask)
