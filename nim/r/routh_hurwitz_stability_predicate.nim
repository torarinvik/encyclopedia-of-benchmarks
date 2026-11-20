type I64Input = ptr UncheckedArray[int64]

const MaxDegree = 4'i64
const MaxParseableLength = 7

proc routh_hurwitz_stability_predicate*(input: I64Input, length: csize_t): int64
    {.cdecl, exportc: "routh_hurwitz_stability_predicate".} =
  if input == nil or length < 1 or length > MaxParseableLength: return -1
  let degree = input[0]
  if degree < 1 or degree > MaxDegree or length != csize_t(degree + 2): return -1

  var coefficients: array[5, int64]
  for index in 0 .. int(degree):
    let value = input[index + 1]
    if value < -3 or value > 3 or (index == 0 and value <= 0): return -1
    coefficients[index] = value

  let width = (int(degree) + 2) div 2
  var table: array[15, int64]
  for column in 0 ..< width:
    let evenIndex = 2 * column
    let oddIndex = evenIndex + 1
    if evenIndex <= int(degree): table[column] = coefficients[evenIndex]
    if oddIndex <= int(degree): table[3 + column] = coefficients[oddIndex]

  var rowOneZero = true
  for column in 0 ..< width:
    if table[3 + column] != 0: rowOneZero = false
  if rowOneZero or table[3] <= 0: return 0

  for row in 2 .. int(degree):
    if table[3 * (row - 1)] <= 0: return 0
    var allZero = true
    for column in 0 ..< width:
      let upperNext = if column + 1 < width: table[3 * (row - 2) + column + 1] else: 0
      let lowerNext = if column + 1 < width: table[3 * (row - 1) + column + 1] else: 0
      table[3 * row + column] = table[3 * (row - 1)] * upperNext - table[3 * (row - 2)] * lowerNext
      if table[3 * row + column] != 0: allZero = false
    if allZero or table[3 * row] <= 0: return 0
  1
