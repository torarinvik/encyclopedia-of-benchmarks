const
  ChachaWords = 16
  ChachaBytes = 64
  WordMask = 0xffff_ffff'u64

proc rotateLeft(value: uint64, count: uint64): uint64 =
  ((value shl count) or (value shr (32'u64 - count))) and WordMask

proc quarterRound(state: var array[ChachaWords, uint64], a, b, c, d: int) =
  state[a] = (state[a] + state[b]) and WordMask
  state[d] = rotateLeft(state[d] xor state[a], 16)
  state[c] = (state[c] + state[d]) and WordMask
  state[b] = rotateLeft(state[b] xor state[c], 12)
  state[a] = (state[a] + state[b]) and WordMask
  state[d] = rotateLeft(state[d] xor state[a], 8)
  state[c] = (state[c] + state[d]) and WordMask
  state[b] = rotateLeft(state[b] xor state[c], 7)

proc chacha(input: ptr UncheckedArray[int64], length: csize_t,
            output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
            {.cdecl, exportc: "chacha".} =
  if input == nil or length != csize_t(ChachaWords): return -1
  var initial: array[ChachaWords, uint64]
  for index in 0 ..< ChachaWords:
    if input[index] < 0 or input[index] > 0xffff_ffff'i64: return -1
    initial[index] = uint64(input[index])
  if output == nil or outputCapacity < csize_t(ChachaBytes): return -2

  var state = initial
  for _ in 0 ..< 10:
    quarterRound(state, 0, 4, 8, 12)
    quarterRound(state, 1, 5, 9, 13)
    quarterRound(state, 2, 6, 10, 14)
    quarterRound(state, 3, 7, 11, 15)
    quarterRound(state, 0, 5, 10, 15)
    quarterRound(state, 1, 6, 11, 12)
    quarterRound(state, 2, 7, 8, 13)
    quarterRound(state, 3, 4, 9, 14)

  for index in 0 ..< ChachaWords:
    let word = (state[index] + initial[index]) and WordMask
    output[4 * index] = uint8(word and 0xff)
    output[4 * index + 1] = uint8((word shr 8) and 0xff)
    output[4 * index + 2] = uint8((word shr 16) and 0xff)
    output[4 * index + 3] = uint8((word shr 24) and 0xff)
  int64(ChachaBytes)
