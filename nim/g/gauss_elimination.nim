import std/strutils

proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset+b] = uint8((bits shr (8*b)) and 0xFF'u64)

proc gauss_elimination*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "gauss_elimination".} =
  if input.isNil or length < 1: return -1
  if input[0] < 2 or input[0] > 8: return -1
  let n = int(input[0])
  if length != csize_t(1 + n*n + n): return -1
  var matrix: array[8, array[9, float32]]
  for row in 0 ..< n:
    for col in 0 ..< n:
      let value = input[1 + row*n + col]
      if value < -100 or value > 100: return -1
      matrix[row][col] = float32(value)
    let rhs = input[1 + n*n + row]
    if rhs < -100 or rhs > 100: return -1
    matrix[row][n] = float32(rhs)
  for step in 0 ..< n-1:
    var pivot = step
    var maximum = abs(matrix[step][step])
    for row in step ..< n:
      let magnitude = abs(matrix[row][step])
      if maximum < magnitude:
        maximum = magnitude
        pivot = row
    if maximum == 0.0'f32: return -1
    if pivot != step:
      for col in 0 .. n: swap(matrix[step][col], matrix[pivot][col])
    for row in step+1 ..< n:
      let factor = -(matrix[row][step] / matrix[step][step])
      for col in 0 .. n: matrix[row][col] = matrix[row][col] + matrix[step][col] * factor
  if matrix[n-1][n-1] == 0.0'f32: return -1
  var solution: array[8, float32]
  for row in countdown(n-1, 0):
    var total = 0.0'f32
    var col = n-1
    while col > row:
      total = total + matrix[row][col] * solution[col]
      dec col
    solution[row] = (matrix[row][n] - total) / matrix[row][row]
  if output.isNil or capacity < csize_t(n*8): return -2
  for i in 0 ..< n:
    putF64Le(output, i*8, parseFloat(formatFloat(float64(solution[i]), ffDecimal, 2)))
  int64(n*8)
