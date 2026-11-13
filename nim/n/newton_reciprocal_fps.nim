const Modulus = 998_244_353'i64

proc power(baseValue, exponentValue: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  result = 1
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent shr 1

proc newton_reciprocal_fps*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "newton_reciprocal_fps".} =
  if input == nil or length < 2 or length > 66: return -1
  if input[0] < 1 or input[0] > 64: return -1
  let n = int(input[0])
  if length != csize_t(n + 1): return -1
  for i in 0 ..< n:
    if input[i + 1] < 0 or input[i + 1] >= Modulus: return -1
  if input[1] == 0: return -1
  let bytes = 8 * n
  if output == nil or capacity < csize_t(bytes): return -2
  var inverse: array[64, int64]
  inverse[0] = power(input[1], Modulus - 2)
  var precision = 1
  while precision < n:
    let width = min(2 * precision, n)
    var correction: array[64, int64]
    for i in 0 ..< width:
      for j in 0 ..< min(precision, width - i):
        correction[i + j] = (correction[i + j] + input[i + 1] * inverse[j]) mod Modulus
    correction[0] = (2 + Modulus - correction[0]) mod Modulus
    for i in 1 ..< width: correction[i] = (Modulus - correction[i]) mod Modulus
    var next: array[64, int64]
    for i in 0 ..< precision:
      for j in 0 ..< width - i:
        next[i + j] = (next[i + j] + inverse[i] * correction[j]) mod Modulus
    inverse = next
    precision = width
  for i in 0 ..< n:
    let bits = uint64(inverse[i])
    for byte in 0 ..< 8: output[8 * i + byte] = uint8((bits shr (8 * byte)) and 255'u64)
  int64(bytes)
