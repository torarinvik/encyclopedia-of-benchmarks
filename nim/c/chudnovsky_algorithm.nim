const MaxPrecision = 12

type
  I64Array = ptr UncheckedArray[int64]
  ByteArray = ptr UncheckedArray[uint8]

proc sqrt10005(): float64 =
  var root = 100.0
  for _ in 0 ..< 8: root = 0.5 * (root + 10005.0 / root)
  root

proc chudnovsky_algorithm*(values: I64Array, length: csize_t, output: ByteArray, capacity: csize_t): int64
    {.cdecl, exportc: "chudnovsky_algorithm".} =
  if values.isNil or length != 1 or values[0] < 1 or values[0] > MaxPrecision: return -1
  let precision = int(values[0])
  let outputLength = if precision == 1: 0 else: precision
  if capacity < csize_t(outputLength) or (outputLength > 0 and output.isNil): return -2
  if precision == 1: return 0

  let pi = (426880.0 * sqrt10005()) / 13591409.0
  var fraction = pi - 3.0
  output[0] = uint8('3')
  output[1] = uint8('.')
  for digit in 0 ..< precision - 2:
    fraction *= 10.0
    let nextDigit = int(fraction)
    output[2 + digit] = uint8(ord('0') + nextDigit)
    fraction -= float64(nextDigit)
  int64(outputLength)
