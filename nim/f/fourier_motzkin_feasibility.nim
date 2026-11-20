const MaxVariables = 3
const MaxInequalities = 6
const MaxRows = 128
const MaxParseableInputLength = 27
const RowWidth = 4

proc fourier_motzkin_feasibility*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "fourier_motzkin_feasibility".} =
  if input == nil or length < csize_t(2) or length > csize_t(MaxParseableInputLength):
    return -1
  let dimensionValue = input[0]
  let countValue = input[1]
  if dimensionValue < 1 or dimensionValue > int64(MaxVariables) or
      countValue < 1 or countValue > int64(MaxInequalities):
    return -1
  let dimension = int(dimensionValue)
  let count = int(countValue)
  if length != csize_t(2 + count * (dimension + 1)):
    return -1

  var current: array[MaxRows * RowWidth, int64]
  var nextRows: array[MaxRows * RowWidth, int64]
  var offset = 2
  for row in 0 ..< count:
    for coordinate in 0 ..< dimension:
      let value = input[offset]
      inc offset
      if value < -3 or value > 3:
        return -1
      current[row * RowWidth + coordinate] = value
    let bound = input[offset]
    inc offset
    if bound < -6 or bound > 6:
      return -1
    current[row * RowWidth + 3] = bound

  var rowCount = count
  for variable in 0 ..< dimension:
    var nextCount = 0
    for row in 0 ..< rowCount:
      if current[row * RowWidth + variable] == 0:
        for column in 0 ..< RowWidth:
          nextRows[nextCount * RowWidth + column] = current[row * RowWidth + column]
        inc nextCount
    for upper in 0 ..< rowCount:
      let positive = current[upper * RowWidth + variable]
      if positive <= 0:
        continue
      for lower in 0 ..< rowCount:
        let negative = current[lower * RowWidth + variable]
        if negative >= 0:
          continue
        if nextCount >= MaxRows:
          return -1
        let upperScale = positive
        let lowerScale = -negative
        for coordinate in 0 ..< dimension:
          if coordinate == variable:
            nextRows[nextCount * RowWidth + coordinate] = 0
          else:
            nextRows[nextCount * RowWidth + coordinate] =
              lowerScale * current[upper * RowWidth + coordinate] +
              upperScale * current[lower * RowWidth + coordinate]
        nextRows[nextCount * RowWidth + 3] =
          lowerScale * current[upper * RowWidth + 3] +
          upperScale * current[lower * RowWidth + 3]
        inc nextCount
    for row in 0 ..< nextCount:
      for column in 0 ..< RowWidth:
        current[row * RowWidth + column] = nextRows[row * RowWidth + column]
        nextRows[row * RowWidth + column] = 0
    rowCount = nextCount

  for row in 0 ..< rowCount:
    if current[row * RowWidth + 3] < 0:
      return 0
  1
