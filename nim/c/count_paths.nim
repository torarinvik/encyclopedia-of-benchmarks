## Count four-neighbor vertex-simple grid paths by recursive DFS.
proc countFrom(values: ptr UncheckedArray[int64], rows, cols: int, row, col: int, visited: uint32): int64 =
  if row < 0 or col < 0 or row >= rows or col >= cols: return 0
  let index = row * cols + col
  let mask = 1'u32 shl index
  if values[2 + index] == 1 or (visited and mask) != 0: return 0
  if row == rows - 1 and col == cols - 1: return 1
  let seen = visited or mask
  var count = 0'i64
  count += countFrom(values, rows, cols, row + 1, col, seen)
  count += countFrom(values, rows, cols, row - 1, col, seen)
  count += countFrom(values, rows, cols, row, col + 1, seen)
  count += countFrom(values, rows, cols, row, col - 1, seen)
  count

proc count_paths*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "count_paths".} =
  if values == nil or length < 3 or values[0] < 1 or values[0] > 5 or values[1] < 1 or values[1] > 5: return -1
  let rows = int(values[0])
  let cols = int(values[1])
  if rows * cols > 25 or length != csize_t(2 + rows * cols): return -1
  for i in 2 ..< int(length):
    if values[i] != 0 and values[i] != 1: return -1
  countFrom(values, rows, cols, 0, 0, 0)
