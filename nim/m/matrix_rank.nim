const MaxInputLength = 66
const MaxDimension = 8
const MatrixRankEpsilon = 1e-10

type I64Input = ptr UncheckedArray[int64]

proc matrixRankIsZero(value: float64): bool =
  let magnitude = if value < 0.0: -value else: value
  magnitude < MatrixRankEpsilon

proc matrix_rank*(values: I64Input, length: csize_t): int64
    {.cdecl, exportc: "matrix_rank".} =
  if values == nil or length < 2 or length > MaxInputLength: return -1
  let rowsValue = values[0]
  let colsValue = values[1]
  if rowsValue < 1 or rowsValue > MaxDimension or colsValue < 1 or colsValue > MaxDimension:
    return -1

  let rows = int(rowsValue)
  let cols = int(colsValue)
  let cells = rows * cols
  if int(length) != 2 + cells: return -1

  var matrix: array[64, float64]
  var rowMarked: array[8, bool]
  for index in 0 ..< cells:
    let cell = values[2 + index]
    if cell != 0 and cell != 1: return -1
    matrix[index] = float64(cell)

  var rank = 0'i64
  for col in 0 ..< cols:
    var pivotRow = rows
    for row in 0 ..< rows:
      if not rowMarked[row] and not matrixRankIsZero(matrix[row * cols + col]):
        pivotRow = row
        break
    if pivotRow == rows: continue

    inc rank
    rowMarked[pivotRow] = true
    let pivotValue = matrix[pivotRow * cols + col]
    for nextCol in col + 1 ..< cols:
      matrix[pivotRow * cols + nextCol] /= pivotValue
    for otherRow in 0 ..< rows:
      if otherRow == pivotRow: continue
      let factor = matrix[otherRow * cols + col]
      if not matrixRankIsZero(factor):
        for nextCol in col + 1 ..< cols:
          matrix[otherRow * cols + nextCol] -= matrix[pivotRow * cols + nextCol] * factor
  rank
