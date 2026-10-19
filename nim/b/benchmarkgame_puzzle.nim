type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

const
  MaxArraySize = 100_000
  MaxRounds = 8
  MaxScansPerArray = 64

proc puzzleRand(state: var uint64): uint32 =
  state = state *% 1_103_515_245'u64 +% 12_345'u64
  let shifted = uint32((state shr 16) and 0xffff_ffff'u64)
  shifted mod 32_767'u32 + 1'u32

proc puzzleRandInt(minimum, maximum: int, state: var uint64): int =
  let range = maximum - minimum + 1
  let draw = puzzleRand(state)
  let offset = int(float64(range) * (float64(draw) / 32_768.0))
  if offset == range: offset + minimum - 1 else: offset + minimum

proc puzzleShuffle(items: var seq[int32], state: var uint64) =
  for index in countdown(items.len - 1, 1):
    let range = index + 1
    let draw = puzzleRand(state)
    let k = int(float64(range) * (float64(draw) / 32_768.0))
    let chosen = if k == range: k - 1 else: k
    swap(items[index], items[chosen])

proc puzzleFindDuplicate(data: seq[int32]): int32 =
  var result = 0'u32
  for index, item in data:
    result = result xor (uint32(index + 1) xor cast[uint32](item))
  result = result xor uint32(data.len)
  cast[int32](result)

proc puzzleStoreI32Le(output: U8Output, offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u32)

proc benchmarkgame_puzzle*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "benchmarkgame_puzzle".} =
  if input == nil or length != 3: return -1
  let rawSize = input[0]
  let rawRounds = input[1]
  let rawScans = input[2]
  if rawSize < 1 or rawSize > MaxArraySize.int64 or rawRounds < 1 or rawRounds > MaxRounds.int64 or
      rawScans < 1 or rawScans > MaxScansPerArray.int64: return -1
  let size = int(rawSize)
  let rounds = int(rawRounds)
  let scans = int(rawScans)
  let outputBytes = rounds * 4
  if outputCapacity < csize_t(outputBytes) or output == nil: return -2

  var randomState = 1'u64
  for round in 0 ..< rounds:
    var data = newSeq[int32](size + 1)
    for index in 0 .. size: data[index] = int32(index)
    data[0] = int32(puzzleRandInt(1, size, randomState))
    puzzleShuffle(data, randomState)
    var duplicate = 0'i32
    for _ in 0 ..< scans: duplicate = puzzleFindDuplicate(data)
    puzzleStoreI32Le(output, round * 4, duplicate)
  int64(outputBytes)
