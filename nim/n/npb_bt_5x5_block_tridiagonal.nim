const Block = 5
const MaxLine = 4
const RowWords = 80
const InvalidResult = -1.0e300

type Matrix5 = array[Block, array[Block, float64]]
type Right6 = array[Block, array[Block + 1, float64]]

proc solveBlock(matrix: Matrix5, right: Right6, answer: var Right6): bool =
  var work: array[Block, array[2 * Block + 1, float64]]
  for r in 0 ..< Block:
    for c in 0 ..< Block: work[r][c] = matrix[r][c]
    for c in 0 .. Block: work[r][Block + c] = right[r][c]
  for pivot in 0 ..< Block:
    var best = pivot
    for r in pivot + 1 ..< Block:
      if abs(work[r][pivot]) > abs(work[best][pivot]): best = r
    if work[best][pivot] == 0.0: return false
    swap(work[pivot], work[best])
    let divisor = work[pivot][pivot]
    for c in pivot ..< 2 * Block + 1: work[pivot][c] /= divisor
    for r in 0 ..< Block:
      if r == pivot: continue
      let factor = work[r][pivot]
      for c in pivot ..< 2 * Block + 1:
        work[r][c] -= factor * work[pivot][c]
  for r in 0 ..< Block:
    for c in 0 .. Block: answer[r][c] = work[r][Block + c]
  true

proc npb_bt_5x5_block_tridiagonal*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "npb_bt_5x5_block_tridiagonal".} =
  if values == nil or length < 1 or length > csize_t(1 + RowWords * MaxLine): return InvalidResult
  if values[0] < 2 or values[0] > MaxLine.int64: return InvalidResult
  let n = int(values[0])
  if length != csize_t(1 + RowWords * n): return InvalidResult

  var lower, diagonal, upper: array[MaxLine, Matrix5]
  var rhs: array[MaxLine, array[Block, float64]]
  for row in 0 ..< n:
    var cursor = 1 + RowWords * row
    for which in 0 ..< 3:
      for r in 0 ..< Block:
        for c in 0 ..< Block:
          let value = values[cursor]
          inc cursor
          if which == 1:
            if r == c:
              if value < 40 or value > 64: return InvalidResult
            elif value < -2 or value > 2: return InvalidResult
            diagonal[row][r][c] = float64(value)
          else:
            if value < -2 or value > 2: return InvalidResult
            if which == 0: lower[row][r][c] = float64(value)
            else: upper[row][r][c] = float64(value)
    for r in 0 ..< Block:
      let value = values[cursor]
      inc cursor
      if value < -1000 or value > 1000: return InvalidResult
      rhs[row][r] = float64(value)
    if row == 0:
      for r in 0 ..< Block:
        for c in 0 ..< Block:
          if lower[row][r][c] != 0.0: return InvalidResult
    if row + 1 == n:
      for r in 0 ..< Block:
        for c in 0 ..< Block:
          if upper[row][r][c] != 0.0: return InvalidResult
    for r in 0 ..< Block:
      var offDiagonal = 0.0
      for c in 0 ..< Block:
        if r != c: offDiagonal += abs(diagonal[row][r][c])
        offDiagonal += abs(lower[row][r][c]) + abs(upper[row][r][c])
      if diagonal[row][r][r] <= offDiagonal: return InvalidResult

  var modifiedUpper: array[MaxLine, Matrix5]
  var modifiedRhs: array[MaxLine, array[Block, float64]]
  for row in 0 ..< n:
    var schur = diagonal[row]
    var reduced = rhs[row]
    if row > 0:
      for r in 0 ..< Block:
        for c in 0 ..< Block:
          for k in 0 ..< Block: schur[r][c] -= lower[row][r][k] * modifiedUpper[row - 1][k][c]
        for k in 0 ..< Block: reduced[r] -= lower[row][r][k] * modifiedRhs[row - 1][k]
    var right: Right6
    var solved: Right6
    for r in 0 ..< Block:
      for c in 0 ..< Block: right[r][c] = upper[row][r][c]
      right[r][Block] = reduced[r]
    if not solveBlock(schur, right, solved): return InvalidResult
    for r in 0 ..< Block:
      modifiedRhs[row][r] = solved[r][Block]
      for c in 0 ..< Block: modifiedUpper[row][r][c] = solved[r][c]

  var solution: array[MaxLine, array[Block, float64]]
  solution[n - 1] = modifiedRhs[n - 1]
  for row in countdown(n - 2, 0):
    for r in 0 ..< Block:
      solution[row][r] = modifiedRhs[row][r]
      for c in 0 ..< Block: solution[row][r] -= modifiedUpper[row][r][c] * solution[row + 1][c]
  var checksum = 0.0
  for row in 0 ..< n:
    for r in 0 ..< Block: checksum += float64(row * Block + r + 1) * solution[row][r]
  checksum
