const MaxPoints = 16

proc integerPower(base: float64, exponent: int): float64 =
  result = 1.0
  for _ in 0 ..< exponent: result *= base

proc choose(n, kInput: int): uint64 =
  let k = min(kInput, n - kInput)
  result = 1
  for index in 1 .. k: result = result * uint64(n - k + index) div uint64(index)

proc roundScaled(value: float64): int64 =
  let scaled = value * 1_000_000.0
  if scaled >= 0.0: int64(scaled + 0.5) else: int64(scaled - 0.5)

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc bezier_curve*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "bezier_curve".} =
  if values == nil or length < 4 or length > 34: return -1
  let pointCountValue = values[0]
  let parameterQ = values[1]
  if pointCountValue < 1 or pointCountValue > MaxPoints or parameterQ < 0 or parameterQ > 1_000_000: return -1
  let pointCount = int(pointCountValue)
  if int(length) != 2 + 2 * pointCount: return -1
  for index in 2 ..< int(length):
    if values[index] < -1_000_000 or values[index] > 1_000_000: return -1
  if output == nil or outputCapacity < 32: return -2

  let degree = pointCount - 1
  let t = float64(parameterQ) / 1_000_000.0
  var x, y, dx, dy: float64
  for index in 0 ..< pointCount:
    let weight = float64(choose(degree, index)) * integerPower(1.0 - t, degree - index) * integerPower(t, index)
    x += weight * float64(values[2 + 2 * index])
    y += weight * float64(values[3 + 2 * index])
  for index in 0 ..< degree:
    let weight = float64(degree) * float64(choose(degree - 1, index)) *
      integerPower(1.0 - t, degree - 1 - index) * integerPower(t, index)
    dx += weight * float64(values[4 + 2 * index] - values[2 + 2 * index])
    dy += weight * float64(values[5 + 2 * index] - values[3 + 2 * index])
  writeI64Le(output, 0, roundScaled(x))
  writeI64Le(output, 8, roundScaled(y))
  writeI64Le(output, 16, roundScaled(dx))
  writeI64Le(output, 24, roundScaled(dy))
  32
