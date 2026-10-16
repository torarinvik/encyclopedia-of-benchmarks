import std/math

const InvalidResult = -1.0e300

proc roundFiveEven(value: float64): float64 =
  let scaled = value * 100_000.0
  let fraction = scaled - floor(scaled)
  if abs(fraction - 0.5) <= 1.0e-7: return InvalidResult
  if value == 0.0: return value
  let negative = value < 0.0
  var normalized = abs(value)
  var exponent = 0
  while normalized < 1.0: normalized *= 2.0; dec exponent
  while normalized >= 2.0: normalized *= 0.5; inc exponent
  let mantissa = uint64(normalized * 4503599627370496.0)
  let shift = 52 - exponent
  if shift > 70: return (if negative: -0.0 else: 0.0)
  let lowProduct = (mantissa and 0xffff_ffff'u64) * 100_000'u64
  let highProduct = (mantissa shr 32) * 100_000'u64
  let shiftedHigh = highProduct shl 32
  let low = lowProduct +% shiftedHigh
  let high = (highProduct shr 32) + (if low < lowProduct: 1'u64 else: 0'u64)
  let quotient = if shift < 64: (low shr shift) or (high shl (64 - shift)) else: high shr (shift - 64)
  let halfBit = if shift - 1 < 64: (low shr (shift - 1)) and 1'u64 else: (high shr (shift - 65)) and 1'u64
  let lowerBits = if shift - 1 < 64:
    (low and ((1'u64 shl (shift - 1)) - 1'u64)) != 0
  else:
    low != 0 or (high and ((1'u64 shl (shift - 65)) - 1'u64)) != 0
  let rounded = quotient + (if halfBit != 0 and (lowerBits or (quotient and 1'u64) != 0): 1'u64 else: 0'u64)
  let result = float64(rounded) / 100000.0
  if negative: -result else: result

proc light_aberration*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "light_aberration".} =
  if values == nil or length != 2: return InvalidResult
  let thetaCode = values[0]
  let betaCode = values[1]
  if thetaCode < -3141592 or thetaCode > 3141592 or betaCode < 0 or betaCode > 999999: return InvalidResult
  let theta = float64(thetaCode) / 1000000.0
  let beta = float64(betaCode) / 1000000.0
  let factor = sqrt((1.0 - beta) / (1.0 + beta))
  let angle = 2.0 * arctan(factor * tan(theta / 2.0))
  roundFiveEven(angle)
