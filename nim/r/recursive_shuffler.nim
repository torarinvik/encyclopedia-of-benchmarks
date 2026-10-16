type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc shuffleRecursive(values: var array[64, int32], item: int, state: var uint64) =
  if item <= 0: return
  shuffleRecursive(values, item - 1, state)
  state = (state * 48_271'u64) mod 2_147_483_647'u64
  let other = int(state mod uint64(item + 1))
  swap(values[item], values[other])

proc recursive_shuffler*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "recursive_shuffler".} =
  const MaxValues = 64
  if input == nil or length < 1 or length > csize_t(MaxValues + 1): return -1
  let seed = input[0]
  if seed < 1 or seed >= 2_147_483_647: return -1
  let count = int(length - 1)
  var values: array[MaxValues, int32]
  for index in 0..<count:
    let value = input[csize_t(index + 1)]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    values[index] = int32(value)
  let byteCount = count * 4
  if outputCapacity < csize_t(byteCount) or (byteCount != 0 and output == nil): return -2
  var state = uint64(seed)
  if count > 1: shuffleRecursive(values, count - 1, state)
  for index in 0..<count:
    let bits = cast[uint32](values[index])
    for byte in 0..<4:
      output[csize_t(index * 4 + byte)] = uint8((bits shr (byte * 8)) and 255'u32)
  int64(count)
