## Row-major backtracking Sudoku solver with row, column, and box masks.

proc searchSudoku(board: var array[81, int64], rows, columns, boxes: var array[9, int],
    position: int): bool =
  var current = position
  while current < 81 and board[current] != 0: inc current
  if current == 81: return true
  let row = current div 9
  let column = current mod 9
  let box = (row div 3) * 3 + column div 3
  for digit in 1 .. 9:
    let bit = 1 shl digit
    if (rows[row] and bit) != 0 or (columns[column] and bit) != 0 or (boxes[box] and bit) != 0:
      continue
    board[current] = digit
    rows[row] = rows[row] or bit
    columns[column] = columns[column] or bit
    boxes[box] = boxes[box] or bit
    if searchSudoku(board, rows, columns, boxes, current + 1): return true
    board[current] = 0
    rows[row] = rows[row] xor bit
    columns[column] = columns[column] xor bit
    boxes[box] = boxes[box] xor bit
  false

proc sudoku_solver*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "sudoku_solver".} =
  if length != 81 or values.isNil: return -1
  var board: array[81, int64]
  var rows, columns, boxes: array[9, int]
  for position in 0 ..< 81:
    let digit = values[position]
    if digit < 0 or digit > 9: return -1
    board[position] = digit
    if digit == 0: continue
    let row = position div 9
    let column = position mod 9
    let box = (row div 3) * 3 + column div 3
    let bit = 1 shl int(digit)
    if (rows[row] and bit) != 0 or (columns[column] and bit) != 0 or (boxes[box] and bit) != 0:
      return -1
    rows[row] = rows[row] or bit
    columns[column] = columns[column] or bit
    boxes[box] = boxes[box] or bit
  if outputCapacity < 324 or output.isNil: return -2
  if not searchSudoku(board, rows, columns, boxes, 0): return -1
  for position in 0 ..< 81:
    let digit = uint32(board[position])
    for byte in 0 ..< 4:
      output[position * 4 + byte] = uint8((digit shr (byte * 8)) and 0xFF'u32)
  81
