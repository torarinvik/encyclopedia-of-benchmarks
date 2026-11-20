const MaxDegree = 8
const MaxIterations = 4
const MaxInputLength = 14
const Modulus = 998244353'i64

proc normalize(value: int64): int64 =
  let remainder = value mod Modulus
  if remainder < 0: remainder + Modulus else: remainder

proc power(baseInput, exponentInput: int64): int64 =
  var base = normalize(baseInput)
  var exponent = exponentInput
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent shr 1
  result

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc bairstow_quadratic_factor_iteration*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "bairstow_quadratic_factor_iteration".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength): return -1
  let degreeValue = input[0]
  if degreeValue < 3 or degreeValue > int64(MaxDegree): return -1
  let degree = int(degreeValue)
  if length != csize_t(degree + 5): return -1
  var coefficients: array[MaxDegree + 1, int64]
  for i in 0 .. degree:
    coefficients[i] = input[1 + i]
    if coefficients[i] < 0 or coefficients[i] >= Modulus: return -1
  var sValue = input[degree + 2]
  var tValue = input[degree + 3]
  let iterationsValue = input[degree + 4]
  if coefficients[degree] == 0 or sValue < 0 or sValue >= Modulus
      or tValue < 0 or tValue >= Modulus or iterationsValue < 1
      or iterationsValue > int64(MaxIterations): return -1
  let iterations = int(iterationsValue)
  var sTrace: array[MaxIterations + 1, int64]
  var tTrace: array[MaxIterations + 1, int64]
  sTrace[0] = sValue
  tTrace[0] = tValue
  for step in 0 ..< iterations:
    var q: array[MaxDegree + 2, int64]
    var r: array[MaxDegree + 2, int64]
    q[degree] = coefficients[degree]
    r[degree] = coefficients[degree]
    for cursor in countdown(degree - 1, 0):
      q[cursor] = normalize(coefficients[cursor] + sValue * q[cursor + 1]
                            + tValue * q[cursor + 2])
      r[cursor] = normalize(q[cursor] + sValue * r[cursor + 1]
                            + tValue * r[cursor + 2])
    let r2 = r[2]
    let r3 = r[3]
    let q0 = q[0]
    let q1 = q[1]
    let ell = normalize(sValue * r2 + tValue * r3)
    let denominator = normalize(r2 * r2 - ell * r3)
    if denominator == 0: return -1
    let inverse = power(denominator, Modulus - 2)
    let deltaS = normalize(r3 * q0 - r2 * q1) * inverse mod Modulus
    let deltaT = normalize(ell * q1 - r2 * q0) * inverse mod Modulus
    sValue = normalize(sValue + deltaS)
    tValue = normalize(tValue + deltaT)
    sTrace[step + 1] = sValue
    tTrace[step + 1] = tValue

  let outputBytes = 8 * (2 * iterations + 3)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  storeI64Le(output, 0, int64(iterations + 1))
  for i in 0 .. iterations:
    storeI64Le(output, 8 * (1 + 2 * i), sTrace[i])
    storeI64Le(output, 8 * (2 + 2 * i), tTrace[i])
  int64(outputBytes)
