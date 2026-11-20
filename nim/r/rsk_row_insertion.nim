type RskInput = ptr UncheckedArray[int64]

const
  MaxN = 8
  InvalidResult = low(int64)

proc rsk_row_insertion*(input: RskInput, length: csize_t): int64
    {.cdecl, exportc: "rsk_row_insertion".} =
  if input.isNil or length < 1 or length > 10: return InvalidResult
  let nValue = input[0]
  if nValue < 0'i64 or nValue > MaxN or length != csize_t(nValue + 1):
    return InvalidResult
  let n = int(nValue)
  var seen: array[MaxN, bool]
  for index in 0 ..< n:
    let value = input[index + 1]
    if value < 0'i64 or value >= nValue or seen[int(value)]: return InvalidResult
    seen[int(value)] = true
  if n == 0: return 0

  var p: array[MaxN * MaxN, int64]
  var q: array[MaxN * MaxN, int64]
  var rowLengths: array[MaxN, int]
  var rowCount = 0
  for step in 1 .. n:
    var value = input[step] + 1
    var row = 0
    while true:
      if row == rowCount:
        p[row * MaxN] = value
        q[row * MaxN] = int64(step)
        rowLengths[row] = 1
        inc rowCount
        break
      var column = 0
      while column < rowLengths[row] and p[row * MaxN + column] < value:
        inc column
      if column == rowLengths[row]:
        p[row * MaxN + column] = value
        q[row * MaxN + column] = int64(step)
        inc rowLengths[row]
        break
      let bumped = p[row * MaxN + column]
      p[row * MaxN + column] = value
      value = bumped
      inc row

  var pRow: array[MaxN, int64]
  var qRow: array[MaxN, int64]
  for row in 0 ..< rowCount:
    for column in 0 ..< rowLengths[row]:
      pRow[int(p[row * MaxN + column] - 1)] = int64(row)
      qRow[int(q[row * MaxN + column] - 1)] = int64(row)
  var code = nValue
  for label in 0 ..< n:
    code = code * 9 + pRow[label] + 1
    code = code * 9 + qRow[label] + 1
  code
