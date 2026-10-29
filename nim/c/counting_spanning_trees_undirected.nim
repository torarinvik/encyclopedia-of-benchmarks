const
  MaxVertices = 7
  MaxEdges = 21
  MaxInputLength = 44
  Modulus = 1_000_000_007'i64

proc modularPower(baseValue, exponentValue: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  result = 1
  while exponent > 0:
    if (exponent and 1) != 0:
      result = (result * base) mod Modulus
    base = (base * base) mod Modulus
    exponent = exponent shr 1

proc counting_spanning_trees_undirected*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "counting_spanning_trees_undirected".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength):
    return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 1 or nValue > int64(MaxVertices) or mValue < 0 or mValue > int64(MaxEdges):
    return -1
  let n = int(nValue)
  let edgeCount = int(mValue)
  if length != csize_t(2 + 2 * edgeCount):
    return -1

  var adjacent: array[MaxVertices, array[MaxVertices, bool]]
  for edge in 0 ..< edgeCount:
    let uValue = input[2 + 2 * edge]
    let vValue = input[3 + 2 * edge]
    if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue or uValue == vValue:
      return -1
    let u = int(uValue)
    let v = int(vValue)
    if adjacent[u][v]:
      return -1
    adjacent[u][v] = true
    adjacent[v][u] = true
  if output == nil or outputCapacity < 8:
    return -2

  let dimension = n - 1
  var matrix: array[MaxVertices, array[MaxVertices, int64]]
  for row in 0 ..< dimension:
    var degree = 0'i64
    for column in 0 ..< n:
      if adjacent[row][column]:
        inc degree
        if column < dimension:
          matrix[row][column] = Modulus - 1
    matrix[row][row] = degree

  var determinant = 1'i64
  for column in 0 ..< dimension:
    var pivot = column
    while pivot < dimension and matrix[pivot][column] == 0:
      inc pivot
    if pivot == dimension:
      determinant = 0
      break
    if pivot != column:
      for j in 0 ..< dimension:
        swap(matrix[column][j], matrix[pivot][j])
      determinant = (Modulus - determinant) mod Modulus
    let pivotValue = matrix[column][column]
    determinant = (determinant * pivotValue) mod Modulus
    let inverse = modularPower(pivotValue, Modulus - 2)
    for row in column + 1 ..< dimension:
      let factor = (matrix[row][column] * inverse) mod Modulus
      for j in column ..< dimension:
        matrix[row][j] = (matrix[row][j] - factor * matrix[column][j] mod Modulus + Modulus) mod Modulus

  let answer = uint64(determinant)
  for byte in 0 ..< 8:
    output[byte] = uint8((answer shr (8 * byte)) and 0xff'u64)
  8
