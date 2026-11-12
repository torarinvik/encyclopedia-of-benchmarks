const MaxT = 8
const MaxComponent = 1_000_000'i64
const MaxOutputBytes = 64

proc nearestQuotient(numerator, denominator: int64): int64 =
  let sign = if numerator < 0: -1'i64 else: 1'i64
  let magnitude = if numerator < 0: -numerator else: numerator
  var quotient = magnitude div denominator
  let remainder = magnitude mod denominator
  if 2 * remainder >= denominator: quotient += 1
  sign * quotient

proc gaussianGcd(arInput, aiInput, brInput, biInput: int64): tuple[realPart, imaginaryPart: int64] =
  var ar = arInput
  var ai = aiInput
  var br = brInput
  var bi = biInput
  while br != 0 or bi != 0:
    let denominator = br * br + bi * bi
    let qr = nearestQuotient(ar * br + ai * bi, denominator)
    let qi = nearestQuotient(ai * br - ar * bi, denominator)
    let rr = ar - (qr * br - qi * bi)
    let ri = ai - (qr * bi + qi * br)
    ar = br
    ai = bi
    br = rr
    bi = ri
  if ar != 0 or ai != 0:
    for _ in 0..<4:
      if ar > 0 and ai >= 0: break
      (ar, ai) = (-ai, ar)
  (ar, ai)

proc writeU32(output: ptr UncheckedArray[uint8], offset: int, value: uint32) =
  output[offset] = uint8(value and 0xff'u32)
  output[offset + 1] = uint8((value shr 8) and 0xff'u32)
  output[offset + 2] = uint8((value shr 16) and 0xff'u32)
  output[offset + 3] = uint8((value shr 24) and 0xff'u32)

proc gcd_of_gaussian_integers*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gcd_of_gaussian_integers".} =
  if input.isNil or length < csize_t(5) or length > csize_t(1 + 4 * MaxT): return -1
  let t64 = input[0]
  if t64 < 1 or t64 > MaxT.int64: return -1
  let t = int(t64)
  if int64(length) != 1 + 4 * t.int64: return -1

  var values: array[MaxT * 4, int64]
  for index in 0..<(4 * t):
    let value = input[index + 1]
    if value < -MaxComponent or value > MaxComponent: return -1
    values[index] = value
  let required = 8 * t
  if output.isNil or capacity < csize_t(required) or required > MaxOutputBytes: return -2

  for test in 0..<t:
    let (real, imaginary) = gaussianGcd(
      values[4 * test], values[4 * test + 1],
      values[4 * test + 2], values[4 * test + 3])
    writeU32(output, 8 * test, uint32(real))
    writeU32(output, 8 * test + 4, uint32(imaginary))
  int64(required)
