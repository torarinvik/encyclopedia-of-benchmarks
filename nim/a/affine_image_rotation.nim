const
  MaxDimension = 8
  MaxCells = 64
  MaxInputLength = 79

type AxisSolution = object
  first: int64
  second: int64
  translation: int64
  valid: bool

proc solveAxis(x, y, target: array[3, int64]): AxisSolution =
  let determinant = x[0] * (y[1] - y[2]) + x[1] * (y[2] - y[0]) + x[2] * (y[0] - y[1])
  if determinant == 0: return
  let first = target[0] * (y[1] - y[2]) + target[1] * (y[2] - y[0]) + target[2] * (y[0] - y[1])
  let second = x[0] * (target[1] - target[2]) + x[1] * (target[2] - target[0]) + x[2] * (target[0] - target[1])
  let translation = x[0] * (y[1] * target[2] - y[2] * target[1]) +
    x[1] * (y[2] * target[0] - y[0] * target[2]) + x[2] * (y[0] * target[1] - y[1] * target[0])
  if first mod determinant != 0 or second mod determinant != 0 or translation mod determinant != 0: return
  result.first = first div determinant
  result.second = second div determinant
  result.translation = translation div determinant
  result.valid = true

proc affine_image_rotation*(input: ptr UncheckedArray[int32], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "affine_image_rotation".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let rowsValue = input[0]
  let colsValue = input[1]
  if rowsValue < 1 or rowsValue > MaxDimension or colsValue < 1 or colsValue > MaxDimension: return -1
  let rows = int(rowsValue)
  let cols = int(colsValue)
  let cells = rows * cols
  if int(length) != 14 + cells: return -1
  var pixels: array[MaxCells, uint8]
  for i in 0 ..< cells:
    if input[2 + i] < 0 or input[2 + i] > 255: return -1
    pixels[i] = uint8(input[2 + i])

  let pointOffset = 2 + cells
  var sx, sy, dx, dy: array[3, int64]
  for i in 0 ..< 3:
    sx[i] = int64(input[pointOffset + 2 * i])
    sy[i] = int64(input[pointOffset + 2 * i + 1])
    dx[i] = int64(input[pointOffset + 6 + 2 * i])
    dy[i] = int64(input[pointOffset + 7 + 2 * i])
    if sx[i] < -16 or sx[i] > 16 or sy[i] < -16 or sy[i] > 16 or
       dx[i] < -16 or dx[i] > 16 or dy[i] < -16 or dy[i] > 16: return -1

  let xAxis = solveAxis(sx, sy, dx)
  let yAxis = solveAxis(sx, sy, dy)
  if not xAxis.valid or not yAxis.valid: return -1
  let a = xAxis.first; let b = xAxis.second; let tx = xAxis.translation
  let c = yAxis.first; let d = yAxis.second; let ty = yAxis.translation
  if a < -2 or a > 2 or b < -2 or b > 2 or c < -2 or c > 2 or d < -2 or d > 2 or tx < -16 or tx > 16 or ty < -16 or ty > 16: return -1
  let determinant = a * d - b * c
  if determinant != -1 and determinant != 1: return -1
  for i in 0 ..< 3:
    if dx[i] != a * sx[i] + b * sy[i] + tx or dy[i] != c * sx[i] + d * sy[i] + ty: return -1

  if output.isNil or capacity < csize_t(cells): return -2
  var written = 0
  for y in 0 ..< cols:
    for x in 0 ..< rows:
      let px = int64(x) - tx
      let py = int64(y) - ty
      let sourceX = (d * px - b * py) div determinant
      let sourceY = (-c * px + a * py) div determinant
      if sourceX >= 0 and sourceX < int64(cols) and sourceY >= 0 and sourceY < int64(rows):
        output[written] = pixels[int(sourceY) * cols + int(sourceX)]
      else:
        output[written] = 0
      inc written
  int64(cells)
