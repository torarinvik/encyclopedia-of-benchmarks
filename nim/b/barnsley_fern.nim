const Q12Offset = 10_000_000_000'i64
const Q6Divisor = 1_000_000'i64

proc roundDivEven(numerator, denominator: int64): int64 =
  let negative = numerator < 0
  let magnitude = uint64(if negative: -numerator else: numerator)
  let divisor = uint64(denominator)
  var quotient = magnitude div divisor
  let remainder = magnitude mod divisor
  if remainder * 2'u64 > divisor or (remainder * 2'u64 == divisor and (quotient and 1'u64) != 0):
    inc quotient
  if negative: -int64(quotient) else: int64(quotient)

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc barnsley_fern*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "barnsley_fern".} =
  if input.isNil or length < 1: return -1
  let iterationValue = input[0]
  if iterationValue < 1 or iterationValue > 4096 or length != csize_t(iterationValue): return -1
  let iterations = int(iterationValue)
  for step in 1 ..< iterations:
    if input[step] < 0 or input[step] >= 10_000: return -1
  let outputLength = iterations * 16
  if output.isNil or capacity < csize_t(outputLength): return -2

  var x = 0'i64
  var y = 0'i64
  putI64Le(output, 0, 0)
  putI64Le(output, 8, 0)
  for step in 1 ..< iterations:
    let sample = input[step]
    var a, b, c, d, f: int64
    if sample < 100:
      d = 16
    elif sample < 8_600:
      a = 85; b = 4; c = -4; d = 85; f = 160
    elif sample < 9_300:
      a = 20; b = -26; c = 23; d = 22; f = 160
    else:
      a = -15; b = 28; c = 26; d = 24; f = 44
    let nextX = roundDivEven(a * x + b * y, 100)
    let nextY = roundDivEven(c * x + d * y, 100) + f * Q12Offset
    x = nextX
    y = nextY
    putI64Le(output, step * 16, roundDivEven(x, Q6Divisor))
    putI64Le(output, step * 16 + 8, roundDivEven(y, Q6Divisor))
  int64(outputLength)
