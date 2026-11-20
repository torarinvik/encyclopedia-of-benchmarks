const MaxQueries = 32
const MaxWords = 2 + 2 * MaxQueries
const WordMask = 0xFFFF_FFFF'u64

proc writeU64Le(output: ptr UncheckedArray[uint8], query: int, value: uint64) =
  for byte in 0 ..< 8:
    output[query * 8 + byte] = uint8((value shr (8 * byte)) and 255'u64)

proc multiply_shift_universal_hash_trace*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc.} =
  if input.isNil or length < 2 or length > csize_t(MaxWords + 1): return -1
  let width = input[0]
  let countValue = input[1]
  if width < 1 or width > 16 or countValue < 0 or countValue > MaxQueries: return -1
  let count = int(countValue)
  if int(length) != 2 + 2 * count: return -1

  for query in 0 ..< count:
    let multiplier = input[2 + 2 * query]
    let key = input[3 + 2 * query]
    if multiplier < 1 or multiplier > 4294967295 or (multiplier and 1) == 0:
      return -1
    if key < 0 or key > 4294967295: return -1

  let required = count * 8
  if (required > 0 and output.isNil) or int(capacity) < required: return -2
  let shift = 32 - int(width)
  for query in 0 ..< count:
    let multiplier = uint64(input[2 + 2 * query])
    let key = uint64(input[3 + 2 * query])
    let lowWord = (multiplier * key) and WordMask
    writeU64Le(output, query, lowWord shr shift)
  int64(required)
