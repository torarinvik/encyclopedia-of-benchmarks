proc minimum_path_sum*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "minimum_path_sum".} =
  if values.isNil or length < 2 or length > 66: return low(int64)
  let rowValue = values[0]
  let columnValue = values[1]
  if rowValue < 1 or rowValue > 8 or columnValue < 1 or columnValue > 8: return low(int64)
  let rows = int(rowValue)
  let columns = int(columnValue)
  if int(length) != 2 + rows * columns: return low(int64)
  var costs: array[8, int64]
  for row in 0 ..< rows:
    for column in 0 ..< columns:
      let cell = values[2 + row * columns + column]
      if cell < 0 or cell > 1000: return low(int64)
      if row == 0 and column == 0: costs[column] = cell
      elif row == 0: costs[column] = costs[column - 1] + cell
      elif column == 0: costs[column] += cell
      else: costs[column] = min(costs[column], costs[column - 1]) + cell
  costs[columns - 1]
