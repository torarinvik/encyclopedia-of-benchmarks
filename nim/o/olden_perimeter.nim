proc visitCells(x, y, span, grid, edge: int64): int64 =
  if span == 1:
    var perimeter = 0'i64
    if x == 0: perimeter += edge
    if x + 1 == grid: perimeter += edge
    if y == 0: perimeter += edge
    if y + 1 == grid: perimeter += edge
    return perimeter

  let half = span div 2
  visitCells(x, y, half, grid, edge) +
    visitCells(x + half, y, half, grid, edge) +
    visitCells(x, y + half, half, grid, edge) +
    visitCells(x + half, y + half, half, grid, edge)

proc olden_perimeter*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "olden_perimeter".} =
  if values.isNil or length != 1: return -1
  let level = values[0]
  if level < 9 or level > 11: return -1
  var grid = 1'i64
  for _ in 0 ..< level: grid *= 2
  let edge = 4096'i64 div grid
  visitCells(0, 0, grid, grid, edge)
