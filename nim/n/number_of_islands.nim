proc flood(values: ptr UncheckedArray[int64], visited: var array[256, bool], rows, cols, row, col: int) =
  if row < 0 or col < 0 or row >= rows or col >= cols: return
  let index = row * cols + col
  if values[2 + index] != 1 or visited[index]: return
  visited[index] = true
  flood(values, visited, rows, cols, row + 1, col)
  flood(values, visited, rows, cols, row - 1, col)
  flood(values, visited, rows, cols, row, col + 1)
  flood(values, visited, rows, cols, row, col - 1)

proc number_of_islands*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "number_of_islands".} =
  if values == nil or length < 3 or values[0] < 1 or values[0] > 16 or values[1] < 1 or values[1] > 16: return -1
  let rows = int(values[0])
  let cols = int(values[1])
  if length != csize_t(2 + rows * cols): return -1
  for i in 2 ..< int(length):
    if values[i] != 0 and values[i] != 1: return -1
  var visited: array[256, bool]
  var count = 0'i64
  for row in 0 ..< rows:
    for col in 0 ..< cols:
      let index = row * cols + col
      if values[2 + index] == 1 and not visited[index]:
        inc count
        flood(values, visited, rows, cols, row, col)
  count
