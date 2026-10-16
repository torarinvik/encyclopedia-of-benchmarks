import std/math

const Gravity = 9.80665
const OutputBytes = 24'i64

proc roundCents(value: float64): int64 =
  let bits = cast[uint64](value)
  let exponent = int((bits shr 52) and 2047'u64)
  if exponent == 0: return 0
  let mantissa = (1'u64 shl 52) or (bits and 4503599627370495'u64)
  let product = mantissa * 25'u64
  let rightShift = 1073 - exponent
  if rightShift >= 59: return 0
  var rounded = product shr rightShift
  let divisor = 1'u64 shl rightShift
  let remainder = product and (divisor - 1'u64)
  let halfway = divisor shr 1
  if remainder > halfway or (remainder == halfway and (rounded and 1'u64) != 0):
    inc rounded
  if (bits shr 63) != 0: -int64(rounded) else: int64(rounded)

proc storeF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc horizontal_projectile_motion*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "horizontal_projectile_motion".} =
  if values == nil or length != 2: return -1
  let velocityMilli = values[0]
  let angleMillidegrees = values[1]
  if velocityMilli < 0 or velocityMilli > 100_000 or
      angleMillidegrees < 1_000 or angleMillidegrees > 90_000: return -1
  if output == nil or outputCapacity < csize_t(OutputBytes): return -2

  let velocity = float64(velocityMilli) / 1000.0
  let angle = float64(angleMillidegrees) / 1000.0
  const PiOver180 = 3.14159265358979323846264338327950288 / 180.0
  let velocitySquared = velocity * velocity
  let distanceRaw = velocitySquared * sin((2.0 * angle) * PiOver180) / Gravity
  let angleSine = sin(angle * PiOver180)
  let sineSquared = angleSine * angleSine
  let heightRaw = velocitySquared * sineSquared / (2.0 * Gravity)
  let timeRaw = (2.0 * velocity) * angleSine / Gravity
  storeF64Le(output, 0, float64(roundCents(distanceRaw)) / 100.0)
  storeF64Le(output, 8, float64(roundCents(heightRaw)) / 100.0)
  storeF64Le(output, 16, float64(roundCents(timeRaw)) / 100.0)
  OutputBytes
