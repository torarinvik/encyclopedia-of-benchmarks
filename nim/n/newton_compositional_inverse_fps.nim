const Modulus = 998_244_353'i64
type Series = array[16, int64]

proc power(baseValue, exponentValue: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  result = 1
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent shr 1

proc multiply(left, right: Series, width: int): Series =
  for i in 0 ..< width:
    for j in 0 ..< width - i:
      result[i + j] = (result[i + j] + left[i] * right[j]) mod Modulus

proc compose(outer, inner: Series, width: int): Series =
  var degree = width
  while degree > 0:
    dec degree
    result = multiply(result, inner, width)
    result[0] = (result[0] + outer[degree]) mod Modulus

proc newton_compositional_inverse_fps*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "newton_compositional_inverse_fps".} =
  if input == nil or length < 3 or length > 18: return -1
  if input[0] < 2 or input[0] > 16: return -1
  let n = int(input[0])
  if length != csize_t(n + 1): return -1
  for i in 0 ..< n:
    if input[i + 1] < 0 or input[i + 1] >= Modulus: return -1
  if input[1] != 0 or input[2] == 0: return -1
  let bytes = 8 * n
  if output == nil or capacity < csize_t(bytes): return -2
  var f, derivative, inverse: Series
  for i in 0 ..< n: f[i] = input[i + 1]
  for i in 1 ..< n: derivative[i - 1] = int64(i) * f[i] mod Modulus
  let inverseLinear = power(f[1], Modulus - 2)
  inverse[1] = inverseLinear
  var precision = 2
  while precision < n:
    let width = min(2 * precision, n)
    var residual = compose(f, inverse, width)
    residual[1] = (residual[1] + Modulus - 1) mod Modulus
    let slope = compose(derivative, inverse, width)
    var reciprocal: Series
    reciprocal[0] = inverseLinear
    for i in 1 ..< width:
      var sum = 0'i64
      for j in 1 .. i: sum = (sum + slope[j] * reciprocal[i - j]) mod Modulus
      reciprocal[i] = (Modulus - sum) * inverseLinear mod Modulus
    let correction = multiply(residual, reciprocal, width)
    for i in 0 ..< width:
      inverse[i] = (inverse[i] + Modulus - correction[i]) mod Modulus
    precision = width
  for i in 0 ..< n:
    let bits = uint64(inverse[i])
    for byte in 0 ..< 8: output[8 * i + byte] = uint8((bits shr (8 * byte)) and 255'u64)
  int64(bytes)
