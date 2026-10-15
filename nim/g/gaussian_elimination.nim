proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset+b] = uint8((bits shr (8*b)) and 0xFF'u64)

proc gaussian_elimination*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "gaussian_elimination".} =
  if input.isNil or length < 1: return -1
  if input[0] < 2 or input[0] > 8: return -1
  let n = int(input[0])
  if length != csize_t(1 + n*n + n): return -1
  var matrix: array[8, array[9, float64]]
  for row in 0 ..< n:
    for col in 0 ..< n:
      let value = input[1 + row*n + col]
      if (row == col and value != 32) or (row != col and value != 0 and value != -1): return -1
      if (row + 1 < col or col + 1 < row) and value != 0: return -1
      if row != col and value != input[1 + col*n + row]: return -1
      matrix[row][col] = float64(value)
    let rhs = input[1 + n*n + row]
    if rhs < -100 or rhs > 100: return -1
    matrix[row][n] = float64(rhs)
  if output.isNil or capacity < csize_t(n*8): return -2
  for step in 0 ..< n-1:
    for row in step+1 ..< n:
      let factor = matrix[row][step] / matrix[step][step]
      for col in step .. n: matrix[row][col] -= factor * matrix[step][col]
  var solution: array[8, float64]
  for row in countdown(n-1, 0):
    var total = 0.0
    for col in row+1 ..< n: total += matrix[row][col] * solution[col]
    solution[row] = (matrix[row][n] - total) / matrix[row][row]
  for i in 0 ..< n: putF64Le(output, i*8, solution[i])
  int64(n*8)
