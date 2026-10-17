import std/math

const MaxInputLength = 18
const MaxDimension = 4

proc exactInteger(value: float64, minimum, maximum: int64): bool =
  if classify(value) in {fcNan, fcInf, fcNegInf}: return false
  if value < float64(minimum) or value > float64(maximum): return false
  float64(int64(value)) == value

proc lu_pivot_decomposition*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "lu_pivot_decomposition".} =
  if input == nil or inputLength < 1 or inputLength > MaxInputLength.csize_t: return -1
  if not exactInteger(input[0], 1, MaxDimension): return -1
  let dimension = int(input[0])
  let matrixElements = dimension * dimension
  if inputLength != csize_t(1 + matrixElements): return -1

  var packedLu: array[16, float64]
  for index in 0 ..< matrixElements:
    if not exactInteger(input[csize_t(index + 1)], -8, 8): return -1
    packedLu[index] = input[csize_t(index + 1)]

  var pivot: array[5, int64]
  for index in 0 .. dimension: pivot[index] = int64(index)

  for column in 0 ..< dimension:
    var maxValue = 0.0
    var maxIndex = column
    for row in column ..< dimension:
      let magnitude = abs(packedLu[row * dimension + column])
      if magnitude > maxValue:
        maxValue = magnitude
        maxIndex = row

    if maxIndex != column:
      swap(pivot[column], pivot[maxIndex])
      for swapColumn in 0 ..< dimension:
        swap(packedLu[column * dimension + swapColumn], packedLu[maxIndex * dimension + swapColumn])
      inc pivot[dimension]

    let pivotValue = packedLu[column * dimension + column]
    if pivotValue == 0.0 or classify(pivotValue) in {fcNan, fcInf, fcNegInf}: return -1
    for row in column + 1 ..< dimension:
      packedLu[row * dimension + column] /= pivotValue
      if classify(packedLu[row * dimension + column]) in {fcNan, fcInf, fcNegInf}: return -1
      for trailingColumn in column + 1 ..< dimension:
        packedLu[row * dimension + trailingColumn] -=
          packedLu[row * dimension + column] * packedLu[column * dimension + trailingColumn]
        if classify(packedLu[row * dimension + trailingColumn]) in {fcNan, fcInf, fcNegInf}: return -1

  let outputLength = matrixElements + dimension + 1
  if output == nil or capacity < csize_t(outputLength): return -2
  for index in 0 ..< matrixElements: output[index] = packedLu[index]
  for index in 0 .. dimension: output[matrixElements + index] = float64(pivot[index])
  int64(outputLength)
