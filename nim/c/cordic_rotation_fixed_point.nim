type
  I64Array = ptr UncheckedArray[int64]
  ByteArray = ptr UncheckedArray[uint8]

const
  CordicScale = 1_000_000_000'i64
  CordicHalfPi = 1_570_796_327'i64
  CordicAngles: array[15, int64] = [
    785_398_163'i64, 463_647_609'i64, 244_978_663'i64, 124_354_995'i64,
    62_418_810'i64, 31_239_833'i64, 15_623_729'i64, 7_812_341'i64,
    3_906_230'i64, 1_953_123'i64, 976_562'i64, 488_281'i64,
    244_141'i64, 122_070'i64, 61_035'i64]
  OutputBytes = 24

proc cordicShiftFloor(value: int64, shift: int): int64 =
  if shift == 0: return value
  let divisor = 1'i64 shl shift
  if value >= 0: return value div divisor
  -((-value + divisor - 1) div divisor)

proc writeFloat64Le(output: ByteArray, offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc cordic_rotation_fixed_point*(values: I64Array, length: csize_t,
    output: ByteArray, capacity: csize_t): int64
    {.cdecl, exportc: "cordic_rotation_fixed_point".} =
  if values.isNil or length < 2 or length > 3: return -1
  if length != 2: return -1
  let angle = values[0]
  let stages = values[1]
  if angle < -3_141_592_653'i64 or angle > 3_141_592_653'i64 or stages < 1 or stages > 16:
    return -1
  if output.isNil or capacity < csize_t(OutputBytes): return -2

  var x = CordicScale
  var y = 0'i64
  var z = angle
  var direction = if z >= 0: 1'i64 else: -1'i64
  if direction > 0:
    let oldX = x
    x = -y
    y = oldX
  else:
    let oldX = x
    x = y
    y = -oldX
  z -= direction * CordicHalfPi
  for shift in 0 ..< int(stages - 1):
    direction = if z >= 0: 1'i64 else: -1'i64
    let oldX = x
    let oldY = y
    x = oldX - direction * cordicShiftFloor(oldY, shift)
    y = oldY + direction * cordicShiftFloor(oldX, shift)
    z -= direction * CordicAngles[shift]

  let scale = 1_000_000_000.0
  writeFloat64Le(output, 0, float64(x) / scale)
  writeFloat64Le(output, 8, float64(y) / scale)
  writeFloat64Le(output, 16, float64(z) / scale)
  int64(OutputBytes)
