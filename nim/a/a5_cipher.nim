type State = object
  r1, r2, r3: uint32

proc parity(value: uint32): uint32 =
  var x = value
  x = x xor (x shr 16); x = x xor (x shr 8); x = x xor (x shr 4); x = x xor (x shr 2); x = x xor (x shr 1)
  x and 1
proc fb1(s: State): uint32 = parity(s.r1 and ((1'u32 shl 13) or (1'u32 shl 16) or (1'u32 shl 17) or (1'u32 shl 18)))
proc fb2(s: State): uint32 = parity(s.r2 and ((1'u32 shl 20) or (1'u32 shl 21)))
proc fb3(s: State): uint32 = parity(s.r3 and ((1'u32 shl 7) or (1'u32 shl 20) or (1'u32 shl 21) or (1'u32 shl 22)))
proc push(register: uint32, width, bit: uint32): uint32 = ((register shl 1) or bit) and ((1'u32 shl width) - 1)

proc initialize(key: uint64, frame: uint32): State =
  var s = State()
  for i in countdown(63, 0):
    let bit = uint32((key shr i) and 1)
    s.r1 = push(s.r1, 19, bit xor fb1(s)); s.r2 = push(s.r2, 22, bit xor fb2(s)); s.r3 = push(s.r3, 23, bit xor fb3(s))
  for i in countdown(21, 0):
    let bit = (frame shr i) and 1
    s.r1 = push(s.r1, 19, bit xor fb1(s)); s.r2 = push(s.r2, 22, bit xor fb2(s)); s.r3 = push(s.r3, 23, bit xor fb3(s))
  s

proc tick(s: var State): uint32 =
  let c1 = (s.r1 shr 8) and 1; let c2 = (s.r2 shr 10) and 1; let c3 = (s.r3 shr 10) and 1
  let majority = uint32(ord(c1 + c2 + c3 >= 2))
  result = ((s.r1 shr 18) xor (s.r2 shr 21) xor (s.r3 shr 22)) and 1
  if c1 == majority: s.r1 = push(s.r1, 19, fb1(s))
  if c2 == majority: s.r2 = push(s.r2, 22, fb2(s))
  if c3 == majority: s.r3 = push(s.r3, 23, fb3(s))

proc nextFrame(frame: uint32): uint32 =
  result = frame
  for i in countdown(21, 0):
    let mask = 1'u32 shl i
    if (result and mask) == 0: return result or mask
    result = result and (not mask)

proc a5_cipher*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "a5_cipher".} =
  if input.isNil or length < 3 or input[2] < 1 or input[2] > 4: return -1
  let blocks = int(input[2])
  if length != csize_t(3 + 4 * blocks): return -1
  let byteCount = blocks * 32
  if output.isNil or outputCapacity < csize_t(byteCount): return -2
  let key = cast[uint64](input[0])
  var frame = uint32(cast[uint64](input[1]) and 0x3fffff'u64)
  for block_index in 0 ..< blocks:
    var state = initialize(key, frame)
    for _ in 0 ..< 100: discard tick(state)
    for i in 0 ..< 32: output[block_index * 32 + i] = 0
    for bit in 0 ..< 228:
      let plain = cast[uint64](input[3 + 4 * block_index + bit div 64])
      let value = uint8((plain shr (bit mod 64)) and 1) xor uint8(tick(state))
      output[block_index * 32 + bit div 8] = output[block_index * 32 + bit div 8] or (value shl (bit mod 8))
    for bit in 228 ..< 256:
      let plain = cast[uint64](input[3 + 4 * block_index + bit div 64])
      let value = uint8((plain shr (bit mod 64)) and 1)
      output[block_index * 32 + bit div 8] = output[block_index * 32 + bit div 8] or (value shl (bit mod 8))
    frame = nextFrame(frame)
  int64(byteCount)
