const Modulus = 998_244_353'i64
const MaxInputLength = 12

proc modPow(baseValue, exponentValue: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent shr 1
  result

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = uint64(value)
  for byte in 0 .. 7:
    output[offset + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc pade_approximant_series_coefficients*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "pade_approximant_series_coefficients".} =
  if input == nil or length < 5 or length > MaxInputLength.csize_t: return -1
  let pValue = input[0]
  let qValue = input[1]
  if qValue < 1 or pValue < qValue or pValue > 4 or qValue > 4 or
      length != (pValue + qValue + 3).csize_t: return -1
  let p = int(pValue)
  let q = int(qValue)
  var coefficients: array[9, uint32]
  for index in 0 .. p + q:
    if input[index + 2] < 0 or input[index + 2] >= Modulus: return -1
    coefficients[index] = uint32(input[index + 2])
  let required = 8 * (p + q + 4)
  if output == nil or capacity < required.csize_t: return -2

  var matrix: array[4, array[5, uint32]]
  for row in 0 ..< q:
    let m = p + 1 + row
    for col in 0 ..< q: matrix[row][col] = coefficients[m - col - 1]
    matrix[row][q] = uint32((Modulus - int64(coefficients[m])) mod Modulus)
  for col in 0 ..< q:
    var pivot = col
    while pivot < q and matrix[pivot][col] == 0: inc pivot
    if pivot == q: return -3
    if pivot != col: swap(matrix[pivot], matrix[col])
    let inverse = modPow(int64(matrix[col][col]), Modulus - 2)
    for j in col .. q:
      matrix[col][j] = uint32(int64(matrix[col][j]) * inverse mod Modulus)
    for row in 0 ..< q:
      if row == col: continue
      let factor = int64(matrix[row][col])
      for j in col .. q:
        let product = factor * int64(matrix[col][j]) mod Modulus
        var difference = int64(matrix[row][j]) - product
        if difference < 0: difference += Modulus
        matrix[row][j] = uint32(difference)

  storeI64Le(output, 0, pValue)
  storeI64Le(output, 8, qValue)
  var offset = 16
  for m in 0 .. p:
    var value = uint64(coefficients[m])
    let last = if m < q: m else: q
    if last > 0:
      for j in 1 .. last:
        value = (value + uint64(coefficients[m - j]) * uint64(matrix[j - 1][q])) mod uint64(Modulus)
    storeI64Le(output, offset, int64(value))
    offset += 8
  storeI64Le(output, offset, 1)
  offset += 8
  for j in 0 ..< q:
    storeI64Le(output, offset, int64(matrix[j][q]))
    offset += 8
  int64(required)
