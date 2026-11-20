import math

type
  I64Input = ptr UncheckedArray[int64]
  ByteOutput = ptr UncheckedArray[uint8]

const
  MinCoordinate = 900'i64
  MaxCoordinate = 1500'i64
  MaxUpdates = 8'i64

proc storeI64Le(output: ByteOutput, offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc roundNano(value: float64): int64 =
  let magnitude = if value < 0.0: 0.0 - value else: value
  let rounded = int64(floor(magnitude * 1_000_000_000.0 + 0.5))
  if value < 0.0: -rounded else: rounded

proc multidimensional_newton_raphson*(input: I64Input, length: csize_t,
    output: ByteOutput, capacity: csize_t): int64
    {.cdecl, exportc: "multidimensional_newton_raphson".} =
  if input.isNil or length < 1 or length > 4: return -1
  if length != 3: return -1
  let xMilli = input[0]
  let yMilli = input[1]
  let updates = input[2]
  if xMilli < MinCoordinate or xMilli > MaxCoordinate or
      yMilli < MinCoordinate or yMilli > MaxCoordinate or
      updates < 1 or updates > MaxUpdates: return -1
  if output.isNil or capacity < 16: return -2

  var x = float64(xMilli) / 1000.0
  var y = float64(yMilli) / 1000.0
  for _ in 0 ..< int(updates):
    let f1 = x * x + y - 3.0
    let f2 = x + y * y - 3.0
    let determinant = 4.0 * x * y - 1.0
    let dx = (2.0 * y * f1 - f2) / determinant
    let dy = (2.0 * x * f2 - f1) / determinant
    x -= dx
    y -= dy
  storeI64Le(output, 0, roundNano(x))
  storeI64Le(output, 8, roundNano(y))
  16
