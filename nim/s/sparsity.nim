const MaxDimension = 63
const MaxInputValues = 3971
const MaxAbsCell = 1_000_000'i64
const InvalidResult = -1.0e300

proc sparsity*(input: ptr UncheckedArray[int64], length: csize_t): float64 {.cdecl, exportc: "sparsity".} =
  if input == nil or length < 2 or length > csize_t(MaxInputValues): return InvalidResult
  let rowsValue = input[0]
  let columnsValue = input[1]
  if rowsValue < 1 or rowsValue > MaxDimension.int64 or columnsValue < 1 or columnsValue > MaxDimension.int64:
    return InvalidResult
  let rows = int(rowsValue)
  let columns = int(columnsValue)
  let total = rows * columns
  if length != csize_t(2 + total): return InvalidResult

  var zeroCount = 0
  for index in 0 ..< total:
    let value = input[2 + index]
    if value < -MaxAbsCell or value > MaxAbsCell: return InvalidResult
    if value == 0: inc zeroCount
  float64(zeroCount) / float64(total)
