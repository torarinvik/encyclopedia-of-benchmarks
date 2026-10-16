proc isSquarefree(number: int64): bool =
  var copy = number
  var divisor = 2'i64
  while divisor * divisor <= copy:
    var multiplicity = 0
    while copy mod divisor == 0:
      copy = copy div divisor
      inc multiplicity
    if multiplicity >= 2: return false
    inc divisor
  true

proc problem203*(depth: int64): int64 {.cdecl, exportc: "problem203".} =
  if depth > 51: return -1
  var row: array[51, int64]
  var values: array[1326, int64]
  row[0] = 1
  values[0] = 1
  var count = 1
  var rowLength = 1
  for rowIndex in 2..int(depth):
    row[rowLength] = 1
    var col = rowLength - 1
    while col > 0:
      row[col] += row[col - 1]
      dec col
    row[0] = 1
    inc rowLength
    for col in 0..<rowLength:
      values[count] = row[col]
      inc count
  for i in 1..<count:
    let value = values[i]
    var j = i
    while j > 0 and values[j - 1] > value:
      values[j] = values[j - 1]
      dec j
    values[j] = value
  var total = 0'i64
  for i in 0..<count:
    if i > 0 and values[i] == values[i - 1]: continue
    if isSquarefree(values[i]): total += values[i]
  total
