const MaxN = 6
const Modulus = 998_244_353'i64
const MaxInputValues = 1 + MaxN * MaxN

proc minorDeterminant(matrix: openArray[int64], n, skipRow, skipColumn: int): int64 =
  let dimension = n - 1
  if dimension == 0: return 1
  var minor: array[MaxN * MaxN, int64]
  var targetRow = 0
  for row in 0 ..< n:
    if row == skipRow: continue
    var targetColumn = 0
    for column in 0 ..< n:
      if column == skipColumn: continue
      minor[targetRow * dimension + targetColumn] = matrix[row * n + column]
      inc targetColumn
    inc targetRow

  var dp: array[1 shl (MaxN - 1), int64]
  dp[0] = 1
  let limit = 1 shl dimension
  for mask in 0 ..< limit:
    var row = 0
    var bits = mask
    while bits != 0:
      row += bits and 1
      bits = bits shr 1
    if row == dimension: continue
    for column in 0 ..< dimension:
      if (mask and (1 shl column)) != 0: continue
      var inversions = 0
      for prior in column + 1 ..< dimension:
        inversions += (mask shr prior) and 1
      let next = mask or (1 shl column)
      let term = (dp[mask] * minor[row * dimension + column]) mod Modulus
      if (inversions and 1) == 0:
        dp[next] = (dp[next] + term) mod Modulus
      else:
        dp[next] = (dp[next] - term + Modulus) mod Modulus
  dp[limit - 1]

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc adjugate_matrix*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "adjugate_matrix".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputValues): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > int64(MaxN): return -1
  let n = int(nValue)
  if length != csize_t(1 + n * n): return -1

  var matrix: array[MaxN * MaxN, int64]
  for index in 0 ..< n * n:
    let value = input[1 + index]
    if value < 0 or value >= Modulus: return -1
    matrix[index] = value

  let outputBytes = 8 * n * n
  if output.isNil or capacity < csize_t(outputBytes): return -2
  for row in 0 ..< n:
    for column in 0 ..< n:
      var value = minorDeterminant(matrix, n, column, row)
      if (row + column) mod 2 == 1 and value != 0: value = Modulus - value
      storeI64Le(output, 8 * (row * n + column), value)
  int64(outputBytes)
