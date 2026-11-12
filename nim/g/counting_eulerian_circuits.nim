const
  MaxVertices = 7
  MaxEdges = 9
  MaxInputLength = 20
  Modulus = 998_244_353'i64

proc modularPower(baseValue, exponentValue: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  result = 1
  while exponent > 0:
    if (exponent and 1) != 0:
      result = (result * base) mod Modulus
    base = (base * base) mod Modulus
    exponent = exponent shr 1

proc counting_eulerian_circuits*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "counting_eulerian_circuits".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength):
    return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 1 or nValue > int64(MaxVertices) or mValue < 1 or mValue > int64(MaxEdges):
    return -1
  let n = int(nValue)
  let edgeCount = int(mValue)
  if length != csize_t(2 + 2 * edgeCount):
    return -1

  var indegree: array[MaxVertices, int]
  var outdegree: array[MaxVertices, int]
  var start = 0
  for edge in 0 ..< edgeCount:
    let uValue = input[2 + 2 * edge]
    let vValue = input[3 + 2 * edge]
    if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue:
      return -1
    let u = int(uValue)
    let v = int(vValue)
    if edge == 0:
      start = u
    inc outdegree[u]
    inc indegree[v]

  var balanced = true
  for vertex in 0 ..< n:
    if indegree[vertex] != outdegree[vertex]:
      balanced = false

  var answer = 0'i64
  if balanced:
    var activeId: array[MaxVertices, int]
    var activeCount = 0
    for vertex in 0 ..< n:
      activeId[vertex] = MaxVertices
      if indegree[vertex] != 0:
        activeId[vertex] = activeCount
        inc activeCount
    let rootId = activeId[start]
    let dimension = activeCount - 1
    var matrix: array[MaxVertices, array[MaxVertices, int64]]
    for edge in 0 ..< edgeCount:
      let u = int(input[2 + 2 * edge])
      let v = int(input[3 + 2 * edge])
      if u == start:
        continue
      var row = activeId[u]
      if row > rootId:
        dec row
      matrix[row][row] = (matrix[row][row] + 1) mod Modulus
      if v != start:
        var column = activeId[v]
        if column > rootId:
          dec column
        matrix[row][column] = (matrix[row][column] + Modulus - 1) mod Modulus

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
    answer = determinant
    for vertex in 0 ..< n:
      for factor in 2 ..< outdegree[vertex]:
        answer = (answer * int64(factor)) mod Modulus

  if output == nil or outputCapacity < 8:
    return -2
  let encoded = uint64(answer)
  for byte in 0 ..< 8:
    output[byte] = uint8((encoded shr (8 * byte)) and 0xff'u64)
  8
