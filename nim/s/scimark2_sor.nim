const MaxRows = 8
const MaxCols = 8
const MaxInput = 3 + MaxRows * MaxCols

proc truncDiv(value, divisor: int64): int64 =
  if value < 0: -( (-value) div divisor ) else: value div divisor

proc scimark2_sor*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "scimark2_sor".} =
  if input == nil or length < 3 or length > MaxInput: return -1
  let rowValue = input[0]
  let colValue = input[1]
  let iterationValue = input[2]
  if rowValue < 2 or rowValue > MaxRows or colValue < 2 or colValue > MaxCols or iterationValue < 0 or iterationValue > 8: return -1
  let rows = int(rowValue)
  let cols = int(colValue)
  let iterations = int(iterationValue)
  if length != csize_t(3 + rows * cols): return -1
  var grid: array[MaxRows * MaxCols, int64]
  for i in 0 ..< rows * cols:
    let value = input[3 + i]
    if value < -1000 or value > 1000: return -1
    grid[i] = value
  for _ in 0 ..< iterations:
    for row in 1 ..< rows - 1:
      for col in 1 ..< cols - 1:
        let index = row * cols + col
        let neighbors = grid[index - cols] + grid[index + cols] + grid[index - 1] + grid[index + 1]
        let numerator = 1250'i64 * neighbors - 1000'i64 * grid[index]
        grid[index] = truncDiv(numerator, 4000'i64)
  for i in 0 ..< rows * cols: result += int64(i + 1) * grid[i]
