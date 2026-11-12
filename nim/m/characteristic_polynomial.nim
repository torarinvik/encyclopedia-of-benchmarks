const
  Modulus = 998244353'i64
  MaxN = 8
  MaxInputValues = 1 + MaxN * MaxN + 1

proc normalize(value: int64): int64 =
  let remainder = value mod Modulus
  if remainder < 0: remainder + Modulus else: remainder

proc multiply(left, right: int64): int64 = (left * right) mod Modulus

proc power(baseValue, exponentValue: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = multiply(result, base)
    base = multiply(base, base)
    exponent = exponent shr 1
  result

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc characteristic_polynomial*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "characteristic_polynomial".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputValues): return -1
  let nValue = input[0]
  if nValue < 0 or nValue > int64(MaxN): return -1
  let n = int(nValue)
  if length != csize_t(1 + n * n): return -1

  var matrix: array[MaxN * MaxN, int64]
  for row in 0 ..< n:
    for column in 0 ..< n:
      let value = input[1 + row * n + column]
      if value < 0 or value >= Modulus: return -1
      matrix[row * MaxN + column] = value

  for column in 0 ..< n:
    if column + 2 >= n: break
    var pivot = column + 1
    while pivot < n and matrix[pivot * MaxN + column] == 0: inc pivot
    if pivot == n: continue
    if pivot != column + 1:
      for k in 0 ..< n:
        swap(matrix[(column + 1) * MaxN + k], matrix[pivot * MaxN + k])
      for row in 0 ..< n:
        swap(matrix[row * MaxN + column + 1], matrix[row * MaxN + pivot])
    let inverse = power(matrix[(column + 1) * MaxN + column], Modulus - 2)
    for row in column + 2 ..< n:
      if matrix[row * MaxN + column] == 0: continue
      let factor = multiply(matrix[row * MaxN + column], inverse)
      for k in 0 ..< n:
        matrix[row * MaxN + k] = normalize(
          matrix[row * MaxN + k] - multiply(factor, matrix[(column + 1) * MaxN + k]))
      for k in 0 ..< n:
        matrix[k * MaxN + column + 1] = normalize(
          matrix[k * MaxN + column + 1] + multiply(factor, matrix[k * MaxN + row]))

  var coefficients: array[(MaxN + 1) * (MaxN + 1), int64]
  coefficients[0] = 1
  for size in 1 .. n:
    for degree in 0 .. size:
      var value = 0'i64
      if degree > 0: value = coefficients[(size - 1) * (MaxN + 1) + degree - 1]
      if degree < size:
        value -= multiply(matrix[(size - 1) * MaxN + size - 1],
          coefficients[(size - 1) * (MaxN + 1) + degree])
      coefficients[size * (MaxN + 1) + degree] = normalize(value)
    var subdiagonalProduct = 1'i64
    var start = size - 2
    while start >= 0:
      subdiagonalProduct = multiply(subdiagonalProduct,
        matrix[(start + 1) * MaxN + start])
      let term = multiply(subdiagonalProduct, matrix[start * MaxN + size - 1])
      for degree in 0 .. start:
        coefficients[size * (MaxN + 1) + degree] = normalize(
          coefficients[size * (MaxN + 1) + degree] -
          multiply(term, coefficients[start * (MaxN + 1) + degree]))
      dec start

  let outputBytes = 8 * (n + 1)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  for degree in 0 .. n:
    storeI64Le(output, 8 * degree, coefficients[n * (MaxN + 1) + degree])
  int64(outputBytes)
