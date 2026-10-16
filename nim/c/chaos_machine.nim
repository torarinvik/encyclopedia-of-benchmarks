## Seeded portable port of the pinned logistic-map/Xorshift machine.
import std/math

proc fractionOne(value: float64): float64 = value - floor(value)
proc roundTen(value: float64): float64 =
  let bits = cast[uint64](value)
  let exponent = (bits shr 52) and 0x7FF'u64
  if exponent == 0: return 0.0
  let mantissa = (1'u64 shl 52) or (bits and ((1'u64 shl 52) - 1))
  let lowProduct = (mantissa and 0xFFFF_FFFF'u64) * 9_765_625'u64
  let highProduct = (mantissa shr 32) * 9_765_625'u64
  let shiftedHigh = highProduct shl 32
  let low = shiftedHigh + lowProduct
  let carry = if low < shiftedHigh: 1'u64 else: 0'u64
  let high = (highProduct shr 32) + carry
  let shift = 1065 - int(exponent)
  if shift > 77: return 0.0
  var rounded: uint64
  var relation = 0
  if shift < 64:
    rounded = (high shl (64 - shift)) or (low shr shift)
    let remainder = low and ((1'u64 shl shift) - 1)
    let half = 1'u64 shl (shift - 1)
    if remainder > half: relation = 1
    if remainder < half: relation = -1
  elif shift == 64:
    rounded = high
    let half = 1'u64 shl 63
    if low > half: relation = 1
    if low < half: relation = -1
  else:
    let upperBits = shift - 64
    rounded = high shr upperBits
    let remainderHigh = high and ((1'u64 shl upperBits) - 1)
    let halfHigh = 1'u64 shl (upperBits - 1)
    if remainderHigh > halfHigh or (remainderHigh == halfHigh and low != 0): relation = 1
    if remainderHigh < halfHigh: relation = -1
  if relation > 0 or (relation == 0 and (rounded and 1) != 0): inc rounded
  float64(rounded) / 10_000_000_000.0
proc pull(machineTime: var int64, buffer: var array[5, float64], params: var array[5, float64]): uint32 =
  let key = int(machineTime mod 5)
  for _ in 0 ..< 3:
    let rate = params[key]
    let value = buffer[key]
    buffer[key] = roundTen(rate * value * (1.0 - value))
    params[key] = fractionOne(float64(machineTime) * 0.01 + rate * 1.01) + 3.0
  var x = uint64(buffer[(key + 2) mod 5] * 10_000_000_000.0)
  var y = uint64(buffer[(key + 3) mod 5] * 10_000_000_000.0)
  inc machineTime
  x = x xor (y shr 13); y = y xor (x shl 17); x = x xor (y shr 5)
  uint32(x and 0xFFFF_FFFF'u64)

proc chaos_machine*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "chaos_machine".} =
  if values == nil or length < 2 or length > csize_t(66): return -1
  let seedCountValue = values[0]
  if seedCountValue < 0 or seedCountValue > 64 or length != csize_t(seedCountValue + 2): return -1
  let seedCount = int(seedCountValue)
  let pullInput = values[int(length) - 1]
  if pullInput < 0 or pullInput > 64: return -1
  for index in 0 ..< seedCount:
    if values[index + 1] < 0 or values[index + 1] > 1_000_000: return -1
  let required = 4 * int(pullInput)
  if csize_t(required) > outputCapacity or (required != 0 and output == nil): return -2
  var buffer = [0.33, 0.44, 0.55, 0.44, 0.33]
  var params: array[5, float64]
  var machineTime = 0'i64
  for index in 0 ..< seedCount:
    let seed = float64(values[index + 1])
    for key in 0 ..< 5:
      if buffer[key] == 0.0: return -1
      let evolution = seed / buffer[key]
      let value = fractionOne(buffer[(key + 1) mod 5] + evolution)
      let rate = fractionOne(params[key] + evolution) + 3.0
      buffer[key] = roundTen(rate * value * (1.0 - value))
      params[key] = rate
    inc machineTime
  for index in 0 ..< int(pullInput):
    let result = pull(machineTime, buffer, params)
    for byte in 0 ..< 4: output[4 * index + byte] = uint8((result shr (8 * byte)) and 255)
  int64(required)
