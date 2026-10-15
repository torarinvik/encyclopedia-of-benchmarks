## Count right-and-down paths with one row of dynamic programming.
proc unique_paths*(rows, columns: uint64): int64 {.cdecl, exportc: "unique_paths".} =
  if rows == 0 or columns == 0 or rows > 34 or columns > 34: return -1
  let width = min(rows, columns)
  let height = max(rows, columns)
  var paths: array[34, int64]
  for column in 0'u64 ..< width:
    paths[int(column)] = 1
  for row in 1'u64 ..< height:
    for column in 1'u64 ..< width:
      paths[int(column)] += paths[int(column - 1)]
  paths[int(width - 1)]
