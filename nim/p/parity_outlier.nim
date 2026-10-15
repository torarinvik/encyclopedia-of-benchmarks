proc parity_outlier*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "parity_outlier".} =
  if values == nil or length < 1 or values[0] < 3 or values[0] > 65 or (values[0] and 1) == 0: return -1
  let count = int(values[0])
  if length != csize_t(count + 1): return -1
  var evens = 0
  var odds = 0
  var evenValue = 0'i64
  var oddValue = 0'i64
  for i in 0 ..< count:
    let value = values[i + 1]
    if value < 0 or value > 2_147_483_647: return -1
    if (value and 1) == 0:
      inc evens
      evenValue = value
    else:
      inc odds
      oddValue = value
  if evens == 1 and odds >= 2: return evenValue
  if odds == 1 and evens >= 2: return oddValue
  -1
