proc problem15*(gridSize: int64): int64 {.cdecl, exportc: "problem15".} =
  if gridSize < 0 or gridSize > 20: return -1
  var paths = 1'i64
  for step in 1'i64..gridSize:
    paths = paths * (gridSize + step) div step
  paths
