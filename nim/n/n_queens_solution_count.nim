const MaxN = 8

proc countFrom(n, column: int, rows: var array[MaxN, bool], down, up: var array[2 * MaxN, bool]): int64 =
  if column == n: return 1
  for row in 0 ..< n:
    let d = row - column + n - 1
    let u = row + column
    if not rows[row] and not down[d] and not up[u]:
      rows[row] = true; down[d] = true; up[u] = true
      result += countFrom(n, column + 1, rows, down, up)
      rows[row] = false; down[d] = false; up[u] = false

proc n_queens_solution_count*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "n_queens_solution_count".} =
  if values.isNil or length != csize_t(1) or values[0] < 0 or values[0] > MaxN: return -1
  var rows: array[MaxN, bool]
  var down, up: array[2 * MaxN, bool]
  countFrom(int(values[0]), 0, rows, down, up)
