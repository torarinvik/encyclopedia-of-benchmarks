const
  TfkMaxElements = 32
  TfkMaxValidInput = 387
  TfkMaxParseableInput = 388
  TfkMaxOutputBytes = 3072

proc tfkStoreI64(staged: var array[TfkMaxOutputBytes, uint8], offset: int,
                 value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    staged[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc tetrahedral_element_force_kernel*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8],
    capacity: csize_t): int64 {.cdecl, exportc: "tetrahedral_element_force_kernel".} =
  if input.isNil or length < 3 or length > TfkMaxParseableInput:
    return -1
  let elementCountValue = input[0]
  let lameLambda = input[1]
  let lameMu = input[2]
  if elementCountValue < 1 or elementCountValue > TfkMaxElements:
    return -1
  if length != csize_t(3 + 12 * elementCountValue):
    return -1
  if lameLambda < 0 or lameLambda > 16 or lameMu < 0 or lameMu > 16:
    return -1
  let elementCount = int(elementCountValue)
  for index in 3 ..< int(length):
    if input[index] < -4 or input[index] > 4:
      return -1

  let required = 96 * elementCount
  if output.isNil or capacity < csize_t(required):
    return -2

  var staged: array[TfkMaxOutputBytes, uint8]
  for element in 0 ..< elementCount:
    let inputBase = 3 + 12 * element
    var deformation: array[9, int64]
    for row in 0 ..< 3:
      for column in 0 ..< 3:
        deformation[3 * row + column] =
          input[inputBase + 3 * (column + 1) + row] - input[inputBase + row]
    let traceDelta = deformation[0] + deformation[4] + deformation[8] - 3'i64

    var stress: array[9, int64]
    for row in 0 ..< 3:
      for column in 0 ..< 3:
        let diagonal = if row == column: 1'i64 else: 0'i64
        stress[3 * row + column] = lameLambda * traceDelta * diagonal + lameMu * (
          deformation[3 * row + column] + deformation[3 * column + row] - 2'i64 * diagonal)

    let outputBase = 12 * element
    for row in 0 ..< 3:
      var rowSum = 0'i64
      for column in 0 ..< 3:
        rowSum += stress[3 * row + column]
      tfkStoreI64(staged, 8 * (outputBase + row), rowSum)
    for vertex in 0 ..< 3:
      for row in 0 ..< 3:
        tfkStoreI64(staged, 8 * (outputBase + 3 * (vertex + 1) + row),
                    -stress[3 * row + vertex])

  for index in 0 ..< required:
    output[index] = staged[index]
  int64(required)
