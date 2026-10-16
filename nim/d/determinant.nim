const MaxDimension = 6
const MaxInputLength = 1 + MaxDimension * MaxDimension
const InvalidResult = low(int64)

proc determinantRecursive(matrix: ptr UncheckedArray[int64], dimension: int): int64 =
  if dimension == 1: return matrix[0]
  var resultValue: int64 = 0
  var minor: array[(MaxDimension - 1) * (MaxDimension - 1), int64]
  for column in 0 ..< dimension:
    var minorIndex = 0
    for row in 1 ..< dimension:
      for sourceColumn in 0 ..< dimension:
        if sourceColumn != column:
          minor[minorIndex] = matrix[row * dimension + sourceColumn]
          inc minorIndex
    let minorPointer = cast[ptr UncheckedArray[int64]](addr minor[0])
    let term = matrix[column] * determinantRecursive(minorPointer, dimension - 1)
    if column mod 2 == 0: resultValue += term
    else: resultValue -= term
  resultValue

proc determinant*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "determinant".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength): return InvalidResult
  let dimensionValue = input[0]
  if dimensionValue < 1 or dimensionValue > MaxDimension: return InvalidResult
  let dimension = int(dimensionValue)
  if length != csize_t(1 + dimension * dimension): return InvalidResult
  for index in 0 ..< dimension * dimension:
    if input[1 + index] < -9 or input[1 + index] > 9: return InvalidResult
  let matrixPointer = cast[ptr UncheckedArray[int64]](addr input[1])
  determinantRecursive(matrixPointer, dimension)
