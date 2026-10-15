proc max_non_adjacent_sum*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "max_non_adjacent_sum".} =
  const invalid = low(int64)
  if values.isNil or length < 1 or length > 100000: return invalid
  var twoBack = 0'i64
  var oneBack = 0'i64
  for i in 0 ..< int(length):
    let value = values[i]
    if value < 0 or value > 10000: return invalid
    let take = twoBack + value
    let current = max(take, oneBack)
    twoBack = oneBack
    oneBack = current
  oneBack
