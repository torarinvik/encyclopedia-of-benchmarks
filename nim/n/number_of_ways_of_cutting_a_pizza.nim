const
  MaxInput = 39
  Modulus = 1_000_000_007'i64

proc numberOfWaysOfCuttingAPizza*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "number_of_ways_of_cutting_a_pizza".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let rowsValue = input[0]
  let columnsValue = input[1]
  let cutsValue = input[2]
  if rowsValue < 1 or rowsValue > 6 or columnsValue < 1 or columnsValue > 6:
    return -1
  if cutsValue < 0 or cutsValue > 5: return -1
  let rows = int(rowsValue)
  let columns = int(columnsValue)
  let cuts = int(cutsValue)
  if length != csize_t(3 + rows * columns): return -1

  var cells: array[36, int64]
  for index in 0 ..< rows * columns:
    let cell = input[3 + index]
    if cell != 0 and cell != 1: return -1
    cells[index] = cell

  var suffix: array[49, int64]
  for rowOffset in 0 ..< rows:
    let row = rows - 1 - rowOffset
    for columnOffset in 0 ..< columns:
      let column = columns - 1 - columnOffset
      let at = row * 7 + column
      suffix[at] = cells[row * columns + column] + suffix[(row + 1) * 7 + column] +
        suffix[row * 7 + column + 1] - suffix[(row + 1) * 7 + column + 1]

  var previous: array[49, int64]
  var current: array[49, int64]
  for row in 0 ..< rows:
    for column in 0 ..< columns:
      if suffix[row * 7 + column] > 0:
        previous[row * 7 + column] = 1

  var remaining = 1
  while remaining <= cuts:
    for index in 0 ..< 49: current[index] = 0
    for rowOffset in 0 ..< rows:
      let row = rows - 1 - rowOffset
      for columnOffset in 0 ..< columns:
        let column = columns - 1 - columnOffset
        let origin = row * 7 + column
        var ways = 0'i64
        for cutRow in row + 1 ..< rows:
          if suffix[origin] - suffix[cutRow * 7 + column] > 0:
            ways += previous[cutRow * 7 + column]
        for cutColumn in column + 1 ..< columns:
          if suffix[origin] - suffix[row * 7 + cutColumn] > 0:
            ways += previous[row * 7 + cutColumn]
        current[origin] = ways mod Modulus
    for index in 0 ..< 49: previous[index] = current[index]
    inc remaining
  return previous[0]
