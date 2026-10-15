const MaxN = 100
const InvalidResult = -10001'i64

proc minimum_falling_path_sum*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "minimum_falling_path_sum".} =
  if input.isNil or length < 1 or input[0] < 1 or input[0] > MaxN:
    return InvalidResult
  let n = int(input[0])
  if int(length) != 1 + n * n: return InvalidResult
  for index in 0 ..< n * n:
    if input[1 + index] < -100 or input[1 + index] > 100: return InvalidResult

  var costs: array[MaxN, int64]
  var nextCosts: array[MaxN, int64]
  for column in 0 ..< n: costs[column] = input[1 + column]
  for row in 1 ..< n:
    for column in 0 ..< n:
      var best = costs[column]
      if column > 0 and costs[column - 1] < best: best = costs[column - 1]
      if column + 1 < n and costs[column + 1] < best: best = costs[column + 1]
      nextCosts[column] = best + input[1 + row * n + column]
    for column in 0 ..< n: costs[column] = nextCosts[column]
  var minimum = costs[0]
  for column in 1 ..< n:
    if costs[column] < minimum: minimum = costs[column]
  minimum
