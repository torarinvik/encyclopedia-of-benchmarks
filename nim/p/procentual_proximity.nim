proc writeF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc procentual_proximity*(input: ptr UncheckedArray[int64], length: csize_t,
                           output: ptr UncheckedArray[uint8], capacity: csize_t): int64
                           {.cdecl, exportc: "procentual_proximity".} =
  if input == nil or length < 3 or length > 522: return -1
  let rowValue = input[0]
  let columnValue = input[1]
  if rowValue < 1 or rowValue > 64 or columnValue < 1 or columnValue > 8: return -1
  let rows = int(rowValue)
  let columns = int(columnValue)
  if int(length) != 2 + columns + rows * columns: return -1
  for column in 0 ..< columns:
    if input[2 + column] != 0 and input[2 + column] != 1: return -1
  var data: array[64, array[8, float64]]
  for row in 0 ..< rows:
    for column in 0 ..< columns:
      let value = input[2 + columns + row * columns + column]
      if value < -10000 or value > 10000: return -1
      data[row][column] = float64(value)
  let outputLength = rows * (columns + 1) * 8
  if output == nil or capacity < csize_t(outputLength): return -2

  var scores: array[64, float64]
  for column in 0 ..< columns:
    var minimum = data[0][column]
    var maximum = data[0][column]
    for row in 1 ..< rows:
      if data[row][column] < minimum: minimum = data[row][column]
      if data[row][column] > maximum: maximum = data[row][column]
    let weight = input[2 + column]
    if minimum == maximum:
      if weight == 0:
        for row in 0 ..< rows: scores[row] += 1.0
    else:
      let valueRange = maximum - minimum
      for row in 0 ..< rows:
        var itemScore = (data[row][column] - minimum) / valueRange
        if weight == 0: itemScore = 1.0 - itemScore
        scores[row] = scores[row] + itemScore

  var offset = 0
  for row in 0 ..< rows:
    for column in 0 ..< columns:
      writeF64Le(output, offset, data[row][column])
      offset += 8
    writeF64Le(output, offset, scores[row])
    offset += 8
  int64(outputLength)
