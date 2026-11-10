const InfCost = 65536'u32

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
  var costs: array[32, uint32]
  var nextCosts: array[32, uint32]
  for row in 0 ..< rows - 1:
    for target in 0 ..< columns: nextCosts[target] = InfCost
    for column in 0 ..< columns:
      let value = int(input[2 + row * columns + column])
      let base = costs[column] + uint32(value)
      for target in 0 ..< columns:
        let candidate = base + uint32(input[moveOffset + value * columns + target])
        nextCosts[target] = min(candidate, nextCosts[target])
    for column in 0 ..< columns: costs[column] = nextCosts[column]
  var minimum = InfCost
  let lastRow = 2 + (rows - 1) * columns
  for column in 0 ..< columns:
    let candidate = costs[column] + uint32(input[lastRow + column])
    if candidate < minimum: minimum = candidate
  int64(minimum)
