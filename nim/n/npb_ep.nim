import std/math

const MaxPairs = 4096
const ModulusMask = (1'u64 shl 46) - 1
const WordMask = (1'u64 shl 23) - 1
const Multiplier = 1_220_703_125'u64
const ModulusScale = 70_368_744_177_664.0

proc isBoundedInteger(value, minimum, maximum: float64): bool =
  value.isFinite and floor(value) == value and value >= minimum and value <= maximum

proc advanceState(state: uint64): uint64 =
  let low = state and WordMask
  let high = state shr 23
  let multiplierLow = Multiplier and WordMask
  let multiplierHigh = Multiplier shr 23
  let lowProduct = low * multiplierLow
  let cross = (low * multiplierHigh + high * multiplierLow) and WordMask
  (lowProduct + (cross shl 23)) and ModulusMask

proc npb_ep*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "npb_ep".} =
  if input.isNil or length != csize_t(2): return -1
  if not isBoundedInteger(input[0], 1.0, float64(MaxPairs)) or
      not isBoundedInteger(input[1], 1.0, 70_368_744_177_663.0): return -1
  let pairCount = int(input[0])
  if output.isNil or capacity < csize_t(12): return -2

  var state = uint64(input[1])
  var histogram: array[10, uint64]
  var sumX = 0.0
  var sumY = 0.0
  for _ in 0 ..< pairCount:
    state = advanceState(state)
    let x = 2.0 * (float64(state) / ModulusScale) - 1.0
    state = advanceState(state)
    let y = 2.0 * (float64(state) / ModulusScale) - 1.0
    let radiusSquared = x * x + y * y
    if radiusSquared <= 0.0 or radiusSquared > 1.0: continue
    let scale = sqrt(-2.0 * ln(radiusSquared) / radiusSquared)
    let normalX = x * scale
    let normalY = y * scale
    let extent = max(abs(normalX), abs(normalY))
    if extent < 10.0: histogram[int(extent)] += 1
    sumX += normalX
    sumY += normalY
  for bin in 0 ..< 10: output[bin] = float64(histogram[bin])
  output[10] = sumX
  output[11] = sumY
  12
