proc validate_sudoku_board*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "validate_sudoku_board".} =
  if input.isNil or length != 81: return -1
  for i in 0 ..< 81:
    if input[i] != int64(ord('.')) and (input[i] < int64(ord('1')) or input[i] > int64(ord('9'))): return -1
  if output.isNil or capacity < 1: return -2
  var rows, columns, boxes: array[9, uint16]
  var valid = true
  for i in 0 ..< 81:
    let value = input[i]
    if value == int64(ord('.')): continue
    let row = i div 9
    let col = i mod 9
    let box = (row div 3) * 3 + col div 3
    let bit = uint16(1 shl int(value - int64(ord('0'))))
    if (rows[row] and bit) != 0 or (columns[col] and bit) != 0 or (boxes[box] and bit) != 0: valid = false
    rows[row] = rows[row] or bit
    columns[col] = columns[col] or bit
    boxes[box] = boxes[box] or bit
  output[0] = uint8(ord(valid))
  1
