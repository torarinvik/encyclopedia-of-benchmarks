const MaxText = 256
const MaxKey = 32

proc columnar_transposition*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "columnar_transposition".} =
  if input == nil or length < 3: return -1
  let operation = input[0]
  let textValue = input[1]
  let rawKeyValue = input[2]
  if (operation != 0 and operation != 1) or textValue < 0 or textValue > MaxText or
      rawKeyValue < 1 or rawKeyValue > MaxKey: return -1
  let textLength = int(textValue)
  let rawKeyLength = int(rawKeyValue)
  if length != csize_t(3 + textLength + rawKeyLength): return -1
  var key: array[MaxKey, uint8]
  var order: array[MaxKey, int]
  var keyLength = 0
  for index in 0 ..< textLength:
    if input[3 + index] < 0 or input[3 + index] > 127: return -1
  for index in 0 ..< rawKeyLength:
    let value = input[3 + textLength + index]
    if value < 0 or value > 127: return -1
    if value >= 65 and value <= 90:
      key[keyLength] = uint8(value)
      inc keyLength
    elif value >= 97 and value <= 122:
      key[keyLength] = uint8(value - 32)
      inc keyLength
  if keyLength == 0: return -1
  for index in 0 ..< keyLength:
    order[index] = index
    var position = index
    while position > 0 and key[order[position - 1]] > key[index]:
      order[position] = order[position - 1]
      dec position
    order[position] = index
  if textLength == 0: return 0
  if output == nil or capacity < csize_t(textLength): return -2
  let rows = (textLength + keyLength - 1) div keyLength
  if operation == 0:
    var written = 0
    for rank in 0 ..< keyLength:
      let column = order[rank]
      for row in 0 ..< rows:
        let index = row * keyLength + column
        if index < textLength:
          output[written] = uint8(input[3 + index])
          inc written
    return int64(written)
  var columnData: array[MaxKey * MaxText, uint8]
  var columnLengths: array[MaxKey, int]
  var offset = 0
  let shortColumns = textLength mod keyLength
  for column in 0 ..< keyLength:
    columnLengths[column] = if shortColumns == 0 or column < shortColumns: rows else: rows - 1
  for rank in 0 ..< keyLength:
    let column = order[rank]
    for row in 0 ..< columnLengths[column]:
      columnData[column * MaxText + row] = uint8(input[3 + offset])
      inc offset
  var written = 0
  for row in 0 ..< rows:
    for column in 0 ..< keyLength:
      if row < columnLengths[column]:
        output[written] = columnData[column * MaxText + row]
        inc written
  int64(written)
