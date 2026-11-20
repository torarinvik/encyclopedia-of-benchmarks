const MaxRows = 6
const MaxColumns = 6
const MaxColors = 6
const ColorSide = 7
const MaxParseableLength = 39

proc strange_printer_ii*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "strange_printer_ii".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxParseableLength): return -1
  let rowsValue = input[0]
  let columnsValue = input[1]
  if rowsValue < 1 or rowsValue > MaxRows or columnsValue < 1 or columnsValue > MaxColumns: return -1
  let rows = int(rowsValue)
  let columns = int(columnsValue)
  if length != csize_t(2 + rows * columns): return -1
  for cell in 0 ..< rows * columns:
    if input[cell + 2] < 1 or input[cell + 2] > MaxColors: return -1

  var firstRow: array[ColorSide, int64]
  var lastRow: array[ColorSide, int64]
  var firstColumn: array[ColorSide, int64]
  var lastColumn: array[ColorSide, int64]
  var outgoing: array[ColorSide, int64]
  var indegree: array[ColorSide, int64]
  var queue: array[ColorSide, int64]
  for color in 0 ..< ColorSide:
    firstRow[color] = rowsValue
    lastRow[color] = -1
    firstColumn[color] = columnsValue
    lastColumn[color] = -1
  for row in 0 ..< rows:
    for column in 0 ..< columns:
      let color = int(input[2 + row * columns + column])
      firstRow[color] = min(firstRow[color], int64(row))
      lastRow[color] = max(lastRow[color], int64(row))
      firstColumn[color] = min(firstColumn[color], int64(column))
      lastColumn[color] = max(lastColumn[color], int64(column))

  var presentCount = 0'i64
  for color in 1 .. MaxColors:
    if lastRow[color] < 0: continue
    inc presentCount
    for row in int(firstRow[color]) .. int(lastRow[color]):
      for column in int(firstColumn[color]) .. int(lastColumn[color]):
        let covered = int(input[2 + row * columns + column])
        let bit = 1'i64 shl covered
        if covered != color and (outgoing[color] and bit) == 0:
          outgoing[color] = outgoing[color] or bit
          inc indegree[covered]
  var head = 0
  var tail = 0
  for color in 1 .. MaxColors:
    if lastRow[color] >= 0 and indegree[color] == 0:
      queue[tail] = int64(color)
      inc tail
  var processed = 0'i64
  while head < tail:
    let color = int(queue[head])
    inc head
    inc processed
    for later in 1 .. MaxColors:
      if (outgoing[color] and (1'i64 shl later)) != 0:
        dec indegree[later]
        if indegree[later] == 0:
          queue[tail] = int64(later)
          inc tail
  if processed == presentCount: return 1
  0
