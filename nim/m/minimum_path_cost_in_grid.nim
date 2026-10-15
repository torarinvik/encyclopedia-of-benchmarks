const InfCost = 1_000_000_000'i64

proc minimum_path_cost_in_grid*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "minimum_path_cost_in_grid".} =
  if input.isNil or length < 2 or input[0] < 1 or input[0] > 32 or input[1] < 1 or input[1] > 32:
    return -1
  let rows = int(input[0])
  let columns = int(input[1])
  let cells = rows * columns
  let moveOffset = 2 + cells
  if int(length) != moveOffset + cells * columns: return -1
  for index in 0 ..< cells:
    if input[2 + index] < 0 or input[2 + index] >= int64(cells): return -1
  for index in 0 ..< cells * columns:
    if input[moveOffset + index] < 1 or input[moveOffset + index] > 100: return -1
  var costs: array[32, int64]
  var nextCosts: array[32, int64]
  for row in 0 ..< rows - 1:
    for target in 0 ..< columns: nextCosts[target] = InfCost
    for column in 0 ..< columns:
      let value = int(input[2 + row * columns + column])
      let base = costs[column] + int64(value)
      for target in 0 ..< columns:
        let candidate = base + input[moveOffset + value * columns + target]
        if candidate < nextCosts[target]: nextCosts[target] = candidate
    for column in 0 ..< columns: costs[column] = nextCosts[column]
  var minimum = InfCost
  let lastRow = 2 + (rows - 1) * columns
  for column in 0 ..< columns:
    let candidate = costs[column] + input[lastRow + column]
    if candidate < minimum: minimum = candidate
  minimum
