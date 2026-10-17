const MaxDimension = 63
const MaxInputValues = 3972
const MaxAbsCell = 1_000_000_000_000'i64
const CellScale = 1.0e12
const Tolerance = 1.0e-9

proc stochastic_matrix*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "stochastic_matrix".} =
  if input == nil or length < 3 or length > csize_t(MaxInputValues): return -1
  let mode = input[0]
  let rowsValue = input[1]
  let columnsValue = input[2]
  if (mode != 0 and mode != 1) or rowsValue < 1 or rowsValue > MaxDimension.int64 or
      columnsValue < 1 or columnsValue > MaxDimension.int64: return -1

  let rows = int(rowsValue)
  let columns = int(columnsValue)
  let total = rows * columns
  if length != csize_t(3 + total): return -1

  for index in 0 ..< total:
    let units = input[3 + index]
    if units < -MaxAbsCell or units > MaxAbsCell: return -1

  if mode == 0:
    for row in 0 ..< rows:
      var sum = 0.0
      for column in 0 ..< columns:
        let value = float64(input[3 + row * columns + column]) / CellScale
        if value < 0.0: return 0
        sum += value
      let difference = sum - 1.0
      if difference > Tolerance or difference < -Tolerance: return 0
  else:
    for column in 0 ..< columns:
      var sum = 0.0
      for row in 0 ..< rows:
        let value = float64(input[3 + row * columns + column]) / CellScale
        if value < 0.0: return 0
        sum += value
      let difference = sum - 1.0
      if difference > Tolerance or difference < -Tolerance: return 0
  1
