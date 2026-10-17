const MaxCells = 16 * 16
const MaxInputLength = 259

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint64](int64(value))
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc spiral_print*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "spiral_print".} =
  if input.isNil or length < 2 or length > MaxInputLength: return -1
  if input[0] < 1 or input[0] > 16 or input[1] < 2 or input[1] > 16: return -1
  let rows = int(input[0])
  let columns = int(input[1])
  let cellCount = rows * columns
  if int(length) != 2 + cellCount: return -1
  var matrix: array[MaxCells, int32]
  for index in 0 ..< cellCount:
    let value = input[2 + index]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    matrix[index] = int32(value)
  let required = 8 * cellCount
  if output.isNil or capacity < csize_t(required): return -2

  var order: array[MaxCells, int32]
  var written = 0
  var top = 0
  var bottom = rows - 1
  var left = 0
  var right = columns - 1
  while top <= bottom and left <= right:
    var column = left
    while column <= right:
      order[written] = matrix[top * columns + column]
      inc written
      inc column
    inc top
    var row = top
    while row <= bottom:
      order[written] = matrix[row * columns + right]
      inc written
      inc row
    dec right
    if top <= bottom and left <= right:
      column = right
      while column >= left:
        order[written] = matrix[bottom * columns + column]
        inc written
        dec column
      dec bottom
    if top <= bottom and left <= right:
      row = bottom
      while row >= top:
        order[written] = matrix[row * columns + left]
        inc written
        dec row
      inc left
  for index in 0 ..< written: writeI64Le(output, index * 8, order[index])
  int64(required)
