const
  Modulus = 998_244_353'i64
  Half = 499_122_177'i64
type Series = array[64, int64]

proc multiply(left, right: Series, width: int): Series =
  for i in 0 ..< width:
    for j in 0 ..< width - i:
      result[i + j] = (result[i + j] + left[i] * right[j]) mod Modulus

proc newton_inverse_sqrt_fps*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "newton_inverse_sqrt_fps".} =
  if input == nil or length < 2 or length > 66: return -1
  if input[0] < 1 or input[0] > 64: return -1
  let n = int(input[0])
  if length != csize_t(n + 1): return -1
  for i in 0 ..< n:
    if input[i + 1] < 0 or input[i + 1] >= Modulus: return -1
  if input[1] != 1: return -1
  let bytes = 8 * n
  if output == nil or capacity < csize_t(bytes): return -2
  var f, inverse: Series
  for i in 0 ..< n: f[i] = input[i + 1]
  inverse[0] = 1
  var precision = 1
  while precision < n:
    let width = min(2 * precision, n)
    let square = multiply(inverse, inverse, width)
    let product = multiply(f, square, width)
    var correction: Series
    correction[0] = (3 + Modulus - product[0]) * Half mod Modulus
    for i in 1 ..< width: correction[i] = (Modulus - product[i]) * Half mod Modulus
    inverse = multiply(inverse, correction, width)
    precision = width
  for i in 0 ..< n:
    let bits = uint64(inverse[i])
    for byte in 0 ..< 8: output[8 * i + byte] = uint8((bits shr (8 * byte)) and 255'u64)
  int64(bytes)
