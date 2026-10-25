## Bounded row-wise minimum-cost path through a grid.
proc rodinia_pathfinder*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "rodinia_pathfinder".} =
  if input.isNil or length < 4 or length > 1027: return -1
  if input[0] < 1 or input[0] > 32 or input[1] < 1 or input[1] > 32 or
      input[2] < 1 or input[2] > 4: return -1
  let cols = int(input[0])
  let rows = int(input[1])
  let height = int(input[2])
  let cells = cols * rows
  if length != csize_t(3 + cells): return -1
  for index in 0 ..< cells:
    if input[3 + index] < 0 or input[3 + index] > 9: return -1
  var previous: array[32, int64]
  var current: array[32, int64]
  for col in 0 ..< cols: previous[col] = input[3 + col]
  var first = 1
  while first < rows:
    let steps = min(height, rows - first)
    for step in 0 ..< steps:
      let row = first + step
      for col in 0 ..< cols:
        var best = previous[col]
        if col > 0 and previous[col - 1] < best: best = previous[col - 1]
        if col + 1 < cols and previous[col + 1] < best: best = previous[col + 1]
        current[col] = best + input[3 + row * cols + col]
      for col in 0 ..< cols: previous[col] = current[col]
    first += height
  var answer = previous[0]
  for col in 1 ..< cols:
    if previous[col] < answer: answer = previous[col]
  answer
