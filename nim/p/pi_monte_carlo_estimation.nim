import std/math

const
  MtN = 624
  MtM = 397
  MaxParseableInputLength = 3

type Mt19937 = object
  state: array[MtN, uint32]
  index: int

proc mtSeed(seed: uint32): Mt19937 =
  result.state[0] = 19_650_218'u32
  for i in 1 ..< MtN:
    let previous = result.state[i - 1]
    result.state[i] = 1_812_433_253'u32 *% (previous xor (previous shr 30)) +% uint32(i)
  var i = 1
  var keyIndex = 0
  for _ in 0 ..< MtN:
    let previous = result.state[i - 1]
    result.state[i] = (result.state[i] xor ((previous xor (previous shr 30)) *% 1_664_525'u32)) +% seed +% uint32(keyIndex)
    inc i
    inc keyIndex
    if i >= MtN:
      result.state[0] = result.state[MtN - 1]
      i = 1
    if keyIndex >= 1:
      keyIndex = 0
  for _ in 0 ..< MtN - 1:
    let previous = result.state[i - 1]
    result.state[i] = (result.state[i] xor ((previous xor (previous shr 30)) *% 1_566_083_941'u32)) -% uint32(i)
    inc i
    if i >= MtN:
      result.state[0] = result.state[MtN - 1]
      i = 1
  result.state[0] = 0x8000_0000'u32
  result.index = MtN

proc mtNextU32(rng: var Mt19937): uint32 =
  if rng.index >= MtN:
    for i in 0 ..< MtN - MtM:
      let joined = (rng.state[i] and 0x8000_0000'u32) or (rng.state[i + 1] and 0x7fff_ffff'u32)
      let magic = if (joined and 1) != 0: 0x9908_b0df'u32 else: 0'u32
      rng.state[i] = rng.state[i + MtM] xor (joined shr 1) xor magic
    for i in MtN - MtM ..< MtN - 1:
      let joined = (rng.state[i] and 0x8000_0000'u32) or (rng.state[i + 1] and 0x7fff_ffff'u32)
      let magic = if (joined and 1) != 0: 0x9908_b0df'u32 else: 0'u32
      rng.state[i] = rng.state[i - (MtN - MtM)] xor (joined shr 1) xor magic
    let joined = (rng.state[MtN - 1] and 0x8000_0000'u32) or (rng.state[0] and 0x7fff_ffff'u32)
    let magic = if (joined and 1) != 0: 0x9908_b0df'u32 else: 0'u32
    rng.state[MtN - 1] = rng.state[MtM - 1] xor (joined shr 1) xor magic
    rng.index = 0
  result = rng.state[rng.index]
  inc rng.index
  result = result xor (result shr 11)
  result = result xor ((result shl 7) and 0x9d2c_5680'u32)
  result = result xor ((result shl 15) and 0xefc6_0000'u32)
  result = result xor (result shr 18)

proc mtRandom(rng: var Mt19937): float64 =
  let high = mtNextU32(rng) shr 5
  let low = mtNextU32(rng) shr 6
  (float64(high) * 67_108_864.0 + float64(low)) * (1.0 / 9_007_199_254_740_992.0)

proc pi_monte_carlo_estimation*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64 {.cdecl, exportc: "pi_monte_carlo_estimation".} =
  if input == nil or inputLength < 1 or inputLength > MaxParseableInputLength.csize_t:
    return -1
  if inputLength != 2:
    return -1
  let simulationsValue = input[0]
  let seedValue = input[1]
  if simulationsValue != simulationsValue or seedValue != seedValue:
    return -1
  if simulationsValue < 1.0 or simulationsValue > 100_000.0 or seedValue < 0.0 or seedValue > 4_294_967_295.0:
    return -1
  if simulationsValue != floor(simulationsValue) or seedValue != floor(seedValue):
    return -1
  if output == nil or outputCapacity < 1:
    return -2

  let simulations = int(simulationsValue)
  var rng = mtSeed(uint32(seedValue))
  var hits = 0
  for _ in 0 ..< simulations:
    let x = mtRandom(rng)
    let y = mtRandom(rng)
    let xSquared = x * x
    let ySquared = y * y
    if xSquared + ySquared <= 1.0:
      inc hits
  output[0] = float64(4 * hits) / float64(simulations)
  return 1
