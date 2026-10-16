const
  MaxDimension = 80
  MaxCellValue = 9999'i64

proc problem81*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "problem81".} =
  if input == nil or length < 1: return -1
  let dimensionValue = input[0]
  if dimensionValue < 1 or dimensionValue > MaxDimension: return -1
  let dimension = int(dimensionValue)
  if length != csize_t(1 + dimension * dimension): return -1
  for index in 1..<int(length):
    if input[index] < 0 or input[index] > MaxCellValue: return -1

  var costs: array[MaxDimension, int64]
  costs[0] = input[1]
  for column in 1..<dimension:
    costs[column] = costs[column - 1] + input[1 + column]
  for row in 1..<dimension:
    let rowOffset = 1 + row * dimension
    costs[0] += input[rowOffset]
    for column in 1..<dimension:
      let above = costs[column]
      let left = costs[column - 1]
      costs[column] = (if above < left: above else: left) + input[rowOffset + column]
  costs[dimension - 1]
