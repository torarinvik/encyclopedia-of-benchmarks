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

  var costs: array[MaxN + 2, uint16]
  var nextCosts: array[MaxN, uint16]
  costs[0] = 32768
  costs[n + 1] = 32768
  for column in 0 ..< n:
    costs[column + 1] = uint16(input[1 + column] + 100)
  for row in 1 ..< n:
    for column in 0 ..< n:
      let best = min(costs[column], min(costs[column + 1], costs[column + 2]))
      nextCosts[column] = best + uint16(input[1 + row * n + column] + 100)
    for column in 0 ..< n:
      costs[column + 1] = nextCosts[column]
  var minimum = costs[1]
  for column in 1 ..< n:
    minimum = min(minimum, costs[column + 1])
  int64(minimum) - 100 * int64(n)
