const
  SalsaWordCount = 16
  SalsaOutputBytes = 64

proc rotateLeft(value: uint32, amount: int): uint32 =
  (value shl amount) or (value shr (32 - amount))

proc quarterRound(state: var array[SalsaWordCount, uint32], first, second, third, fourth: int) =
  state[second] = state[second] xor rotateLeft(state[first] +% state[fourth], 7)
  state[third] = state[third] xor rotateLeft(state[second] +% state[first], 9)
  state[fourth] = state[fourth] xor rotateLeft(state[third] +% state[second], 13)
  state[first] = state[first] xor rotateLeft(state[fourth] +% state[third], 18)

proc storeU32Le(output: ptr UncheckedArray[uint8], offset: int, value: uint32) =
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((value shr (byte * 8)) and 255'u32)

## Reproduce the pinned 16-word Salsa core variant; this is not a stream cipher.
proc salsa*(input: ptr UncheckedArray[int32], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "salsa".} =
  if input == nil or length != SalsaWordCount: return -1
  var original: array[SalsaWordCount, uint32]
  for index in 0 ..< SalsaWordCount:
    original[index] = cast[uint32](input[index])
  if output == nil or outputCapacity < SalsaOutputBytes: return -2

  var state = original
  for _ in 0 ..< 10:
    quarterRound(state, 0, 4, 8, 12)
    quarterRound(state, 5, 9, 13, 1)
    quarterRound(state, 10, 14, 2, 6)
    quarterRound(state, 15, 3, 7, 11)
    quarterRound(state, 0, 1, 2, 3)
    quarterRound(state, 5, 6, 7, 4)
    quarterRound(state, 10, 11, 8, 9)
    quarterRound(state, 15, 12, 13, 14)
  for index in 0 ..< SalsaWordCount:
    state[index] = state[index] +% original[index]
    storeU32Le(output, index * 4, state[index])
  int64(SalsaOutputBytes)
