const
  Slots = 16
  Features = 3
  MaxOperations = 64
  BaseWords = 1 + Slots * Features + Slots
  MaxValidWords = BaseWords + 2 * MaxOperations

proc storeHash(output: ptr UncheckedArray[uint8], offset: int, value: uint64) =
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((value shr (8 * byte)) and 255'u64)

proc zobrist_position_hash_trace*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "zobrist_position_hash_trace".} =
  if input.isNil or length < csize_t(BaseWords) or length > csize_t(MaxValidWords + 1): return -1
  let countValue = input[0]
  if countValue < 0 or countValue > MaxOperations: return -1
  let count = int(countValue)
  if length != csize_t(BaseWords + 2 * count): return -1

  for index in 0 ..< Slots * Features:
    if input[1 + index] < 0: return -1
  let stateStart = 1 + Slots * Features
  for slot in 0 ..< Slots:
    if input[stateStart + slot] < 0 or input[stateStart + slot] > Features: return -1
  let editsStart = stateStart + Slots
  for edit in 0 ..< count:
    let slot = input[editsStart + 2 * edit]
    let feature = input[editsStart + 2 * edit + 1]
    if slot < 0 or slot >= Slots or feature < 0 or feature > Features: return -1

  let required = 8 * (count + 1)
  if output.isNil or capacity < csize_t(required): return -2

  var board: array[Slots, uint8]
  var hash = 0'u64
  for slot in 0 ..< Slots:
    let feature = uint8(input[stateStart + slot])
    board[slot] = feature
    if feature != 0:
      hash = hash xor cast[uint64](input[1 + slot * Features + int(feature) - 1])
  storeHash(output, 0, hash)
  for edit in 0 ..< count:
    let slot = int(input[editsStart + 2 * edit])
    let next = uint8(input[editsStart + 2 * edit + 1])
    let previous = board[slot]
    if previous != 0:
      hash = hash xor cast[uint64](input[1 + slot * Features + int(previous) - 1])
    if next != 0:
      hash = hash xor cast[uint64](input[1 + slot * Features + int(next) - 1])
    board[slot] = next
    storeHash(output, 8 * (edit + 1), hash)
  int64(required)
