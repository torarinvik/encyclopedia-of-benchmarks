const MaxVertices = 16
const MaxParseableLength = 34
const Scale = 1_000_000'i64

proc roundedMicro(numeratorInput, denominatorInput: int64): int64 =
  var numerator = numeratorInput
  var denominator = denominatorInput
  if denominator < 0:
    numerator = -numerator
    denominator = -denominator
  let sign = if numerator < 0: -1'i64 else: 1'i64
  let scaled = uint64(abs(numerator)) * uint64(Scale)
  let divisor = uint64(denominator)
  var quotient = scaled div divisor
  if 2'u64 * (scaled mod divisor) >= divisor: inc quotient
  sign * int64(quotient)

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc polygon_area_centroid*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "polygon_area_centroid".} =
  if input == nil or length < 7 or length > csize_t(MaxParseableLength): return -1
  let countValue = input[0]
  if countValue < 3 or countValue > MaxVertices: return -1
  let count = int(countValue)
  if length != csize_t(1 + 2 * count): return -1

  var xs: array[MaxVertices, int64]
  var ys: array[MaxVertices, int64]
  for i in 0 ..< count:
    let x = input[1 + 2 * i]
    let y = input[2 + 2 * i]
    if x < -50 or x > 50 or y < -50 or y > 50: return -1
    for j in 0 ..< i:
      if xs[j] == x and ys[j] == y: return -1
    xs[i] = x
    ys[i] = y

  var twiceArea = 0'i64
  for i in 0 ..< count:
    let next = (i + 1) mod count
    twiceArea += xs[i] * ys[next] - xs[next] * ys[i]
  if twiceArea == 0: return -1
  let orientation = if twiceArea > 0: 1'i64 else: -1'i64
  for i in 0 ..< count:
    let next = (i + 1) mod count
    for j in 0 ..< count:
      if j == i or j == next: continue
      let side = (xs[next] - xs[i]) * (ys[j] - ys[i]) -
                 (ys[next] - ys[i]) * (xs[j] - xs[i])
      if side * orientation <= 0: return -1

  var numeratorX = 0'i64
  var numeratorY = 0'i64
  for i in 0 ..< count:
    let next = (i + 1) mod count
    let cross = xs[i] * ys[next] - xs[next] * ys[i]
    numeratorX += (xs[i] + xs[next]) * cross
    numeratorY += (ys[i] + ys[next]) * cross
  let xMicro = roundedMicro(numeratorX, 3 * twiceArea)
  let yMicro = roundedMicro(numeratorY, 3 * twiceArea)
  if output == nil or capacity < 16: return -2
  storeI64Le(output, 0, xMicro)
  storeI64Le(output, 8, yMicro)
  16
