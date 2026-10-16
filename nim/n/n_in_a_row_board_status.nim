## Check full rows, columns, and diagonals for one square-board player.
proc n_in_a_row_board_status*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "n_in_a_row_board_status".} =
  if values == nil or length < 2 or length > 258 or values[0] < 2 or values[0] > 16 or
      (values[1] != 1 and values[1] != 2): return -1
  let size = int(values[0])
  let player = values[1]
  if int(length) != 2 + size * size: return -1
  for index in 0 ..< size * size:
    if values[2 + index] < 0 or values[2 + index] > 2: return -1

  var hasEmpty = false
  for row in 0 ..< size:
    var rowWin = true
    for column in 0 ..< size:
      let cell = values[2 + row * size + column]
      if cell == 0: hasEmpty = true
      if cell != player: rowWin = false
    if rowWin: return 1
  for column in 0 ..< size:
    var columnWin = true
    for row in 0 ..< size:
      if values[2 + row * size + column] != player: columnWin = false
    if columnWin: return 1
  var mainDiagonalWin = true
  var antiDiagonalWin = true
  for index in 0 ..< size:
    if values[2 + index * size + index] != player: mainDiagonalWin = false
    if values[2 + index * size + size - 1 - index] != player: antiDiagonalWin = false
  if mainDiagonalWin or antiDiagonalWin: return 1
  if hasEmpty: 0 else: 2
