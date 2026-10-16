proc problem15Dp*(gridSize: int64): int64 {.cdecl, exportc: "problem15_dp".} =
  if gridSize < 0 or gridSize > 20: return -1
  var counts: array[21, array[21, int64]]
  for row in 0..20:
    for column in 0..20:
      counts[row][column] = 1
  for row in 1'i64..gridSize:
    for column in 1'i64..gridSize:
      counts[int(row)][int(column)] = counts[int(row - 1)][int(column)] + counts[int(row)][int(column - 1)]
  counts[int(gridSize)][int(gridSize)]
