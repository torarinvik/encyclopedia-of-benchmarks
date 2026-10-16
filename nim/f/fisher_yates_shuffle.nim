type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc fisher_yates_shuffle*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "fisher_yates_shuffle".} =
  const MaxValues = 1024
  const Modulus = 2_147_483_647'u64
  if input == nil or length < 1 or length > csize_t(MaxValues + 1): return -1
  let seed = input[0]
  if seed < 1 or seed >= int64(Modulus): return -1
  let count = int(length - 1)
  var values: array[MaxValues, int32]
  for i in 0..<count:
    let value = input[csize_t(i + 1)]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    values[i] = int32(value)
  let byteCount = count * 4
  if outputCapacity < csize_t(byteCount) or (byteCount != 0 and output == nil): return -2
  var state = uint64(seed)
  var remaining = count
  while remaining >= 2:
    state = (state * 48_271'u64) mod Modulus
    let other = int(state mod uint64(remaining))
    swap(values[remaining - 1], values[other])
    dec remaining
  for i in 0..<count:
    let bits = cast[uint32](values[i])
    for byte in 0..<4:
      output[csize_t(i * 4 + byte)] = uint8((bits shr (byte * 8)) and 255'u32)
  int64(count)
