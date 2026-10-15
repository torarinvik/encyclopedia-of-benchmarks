## Compute one row of Pascal's triangle using in-place dynamic programming.
proc pascal_triangle_row*(rowIndex: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "pascal_triangle_row".} =
  if rowIndex < 0 or rowIndex > 33: return -1
  let count = int(rowIndex) + 1
  let required = csize_t(count * 4)
  if output == nil or outputCapacity < required: return -2

  var coefficients: array[34, uint32]
  for column in 0 ..< count: coefficients[column] = 1
  for row in 2 .. int(rowIndex):
    var column = row - 1
    while column > 0:
      coefficients[column] += coefficients[column - 1]
      dec column

  var position = 0
  for column in 0 ..< count:
    for byte in 0 ..< 4:
      output[position] = uint8((coefficients[column] shr (byte * 8)) and 0xff'u32)
      inc position
  int64(position)
