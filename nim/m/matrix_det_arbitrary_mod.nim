const MaxN = 8
const MaxInputValues = 2 + MaxN * MaxN + 1
const MaxModulus = 1_000_000_000'i64

proc normalize(value, modulus: int64): int64 =
  result = value mod modulus
  if result < 0: result += modulus

proc storeI64Le(output: ptr UncheckedArray[uint8], value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[byte] = uint8((bits shr (8 * byte)) and 255)

proc matrix_det_arbitrary_mod*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "matrix_det_arbitrary_mod".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputValues): return -1
  let nValue = input[0]
  let modulus = input[1]
  if nValue < 0 or nValue > int64(MaxN) or modulus < 2 or modulus > MaxModulus: return -1
  let n = int(nValue)
  if length != csize_t(2 + n * n): return -1

  var matrix: array[MaxN * MaxN, int64]
  for row in 0 ..< n:
    for column in 0 ..< n:
      let value = input[2 + row * n + column]
      if value < 0 or value >= modulus: return -1
      matrix[row * n + column] = value

  var determinant = 1'i64
  var sign = false
  for column in 0 ..< n:
    var pivot = column
    while pivot < n and matrix[pivot * n + column] == 0: inc pivot
    if pivot == n:
      determinant = 0
      break
    if pivot != column:
      for k in 0 ..< n: swap(matrix[column * n + k], matrix[pivot * n + k])
      sign = not sign
    for row in column + 1 ..< n:
      var left = matrix[column * n + column]
      var right = matrix[row * n + column]
      if right == 0: continue
      var a0 = 1'i64
      var a1 = 0'i64
      var b0 = 0'i64
      var b1 = 1'i64
      while left != 0 and right != 0:
        if left < right:
          let quotient = right div left
          right -= quotient * left
          b0 = normalize(b0 - a0 * quotient, modulus)
          b1 = normalize(b1 - a1 * quotient, modulus)
        else:
          let quotient = left div right
          left -= quotient * right
          a0 = normalize(a0 - b0 * quotient, modulus)
          a1 = normalize(a1 - b1 * quotient, modulus)
      for k in column ..< n:
        let oldTop = matrix[column * n + k]
        let oldBottom = matrix[row * n + k]
        matrix[column * n + k] = normalize(oldTop * a0 + oldBottom * a1, modulus)
        matrix[row * n + k] = normalize(oldTop * b0 + oldBottom * b1, modulus)
      if left == 0:
        for k in 0 ..< n: swap(matrix[column * n + k], matrix[row * n + k])
        sign = not sign
    determinant = (determinant * matrix[column * n + column]) mod modulus
    if determinant == 0: break
  if sign and determinant != 0: determinant = modulus - determinant
  if output.isNil or capacity < 8: return -2
  storeI64Le(output, determinant)
  8
