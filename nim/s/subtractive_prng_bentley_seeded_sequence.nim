const
  StateSize = 55
  ShortLag = 24
  WarmupValues = 165
  Modulus = 1_000_000_000'i32
  MaxCount = 64

type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]
  SeedState = array[StateSize, int32]
  RingState = array[StateSize, int32]

proc putI64Le(output: U8Output, offset: int, value: int32) =
  let bits = uint64(value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc subtractive_prng_bentley_seeded_sequence*(input: I64Input,
    length: csize_t, output: U8Output, capacity: csize_t): int64
    {.cdecl, exportc: "subtractive_prng_bentley_seeded_sequence".} =
  if input.isNil or length != 2: return -1
  let seed = input[0]
  let count = input[1]
  if seed < 0 or seed >= 1_000_000_000'i64 or count < 0 or count > MaxCount:
    return -1
  let n = int(count)
  let required = n * 8
  if capacity < csize_t(required) or (required > 0 and output.isNil): return -2
  if n == 0: return 0

  var seedState: SeedState
  var ring: RingState
  seedState[0] = int32(seed)
  seedState[1] = 1
  for i in 2 ..< StateSize:
    var value = seedState[i - 2] - seedState[i - 1]
    if value < 0: value += Modulus
    seedState[i] = value
  for i in 0 ..< StateSize:
    ring[i] = seedState[(34 * (i + 1)) mod StateSize]

  var writeIndex = 0
  var lagIndex = StateSize - ShortLag
  for step in 0 ..< WarmupValues + n:
    var value = ring[writeIndex] - ring[lagIndex]
    if value < 0: value += Modulus
    ring[writeIndex] = value
    if step >= WarmupValues:
      putI64Le(output, (step - WarmupValues) * 8, value)
    writeIndex = (writeIndex + 1) mod StateSize
    lagIndex = (lagIndex + 1) mod StateSize
  int64(required)
