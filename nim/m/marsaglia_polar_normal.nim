import std/math

const MaxDraws = 128
const MaxAttempts = 64
const DrawScale = 2_147_483_648.0

proc isBoundedInteger(value, minimum, maximum: float64): bool =
  value.isFinite and floor(value) == value and value >= minimum and value <= maximum

proc marsaglia_polar_normal*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "marsaglia_polar_normal".} =
  if input.isNil or length < csize_t(4) or length > csize_t(2 + MaxDraws): return -1
  if not isBoundedInteger(input[0], 2.0, float64(MaxDraws)) or
      not isBoundedInteger(input[1], 1.0, float64(MaxAttempts)): return -1
  let drawCount = int(input[0])
  let attemptCap = int(input[1])
  if drawCount mod 2 != 0 or length != csize_t(2 + drawCount) or drawCount < 2 * attemptCap: return -1
  for index in 0 ..< drawCount:
    if not isBoundedInteger(input[2 + index], 0.0, 4_294_967_295.0): return -1

  var first = 0.0
  var second = 0.0
  var accepted = false
  for attempt in 0 ..< attemptCap:
    let u1 = input[2 + 2 * attempt] / DrawScale - 1.0
    let u2 = input[3 + 2 * attempt] / DrawScale - 1.0
    let radiusSquared = u1 * u1 + u2 * u2
    if radiusSquared <= 0.0 or radiusSquared >= 1.0: continue
    let scale = sqrt(-2.0 * ln(radiusSquared) / radiusSquared)
    first = u1 * scale
    second = u2 * scale
    accepted = true
    break
  if not accepted: return -1
  if output.isNil or capacity < csize_t(2): return -2
  output[0] = first
  output[1] = second
  2
